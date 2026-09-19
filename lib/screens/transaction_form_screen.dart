import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_transaction.dart';
import '../models/category.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_background.dart';
import '../widgets/category_avatar.dart';

class TransactionFormScreen extends StatefulWidget {
  final AppTransaction? initial;

  const TransactionFormScreen({super.key, this.initial});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  late TransactionType _type;
  late int _cents;
  late int? _categoryId;
  late DateTime _date;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  bool _saving = false;
  late final FocusNode _amountFocus = FocusNode();
  late final FocusNode _noteFocus = FocusNode();

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? TransactionType.expense;
    _cents = initial?.amountCents ?? 0;
    _categoryId = initial?.categoryId;
    _date = initial?.date ?? DateTime.now();
    _amountController = TextEditingController(
      text: CurrencyFormatter.formatCents(_cents, ''),
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
    _amountFocus.addListener(_onAmountFocusChange);
  }

  @override
  void dispose() {
    _amountFocus.removeListener(_onAmountFocusChange);
    _amountController.dispose();
    _noteController.dispose();
    _noteFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    _cents = CurrencyFormatter.parseCentsFromInput(value);
    setState(() {});
  }

  void _onAmountFocusChange() {
    if (_amountFocus.hasFocus) {
      if (_amountController.text.isNotEmpty && _cents == 0) {
        _amountController.text = '';
      }
      return;
    }
    final cents = _cents;
    _amountController.text = CurrencyFormatter.formatCents(cents, '');
    _amountController.selection = TextSelection.collapsed(
      offset: _amountController.text.length,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_cents <= 0) {
      _showSnack('Enter an amount greater than zero.');
      return;
    }
    if (_categoryId == null) {
      _showSnack('Pick a category.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final note = _noteController.text.trim();
    try {
      if (_isEdit) {
        await state.updateTransaction(
          widget.initial!.copyWith(
            type: _type,
            amountCents: _cents,
            categoryId: _categoryId,
            note: note,
            date: _date,
          ),
        );
      } else {
        await state.addTransaction(
          type: _type,
          amountCents: _cents,
          categoryId: _categoryId!,
          note: note.isEmpty ? null : note,
          date: _date,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final state = context.read<AppState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await state.deleteTransaction(widget.initial!);
    if (mounted) Navigator.of(context).pop();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final relevantCategories = _type == TransactionType.income
        ? state.incomeCategories
        : state.expenseCategories;
    final symbol = state.settings.currencySymbol;

    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(_isEdit ? 'Edit transaction' : 'New transaction'),
            actions: [
              if (_isEdit)
                IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _type = selection.first;
                      _categoryId = null;
                    });
                  },
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        onChanged: _onAmountChanged,
                        autofocus: !_isEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final category in relevantCategories)
                      _CategoryChoice(
                        category: category,
                        selected: _categoryId == category.id,
                        onTap: () => setState(() => _categoryId = category.id),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date', style: TextStyle(fontSize: 15)),
                  trailing: Text(
                    DateFormat('EEE, d MMM yyyy').format(_date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  focusNode: _noteFocus,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g. Lunch with friends',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Add transaction'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChoice({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? scheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryAvatar(category: category),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
