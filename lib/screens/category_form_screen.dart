import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/app_state.dart';
import '../utils/icon_lookup.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? initial;

  const CategoryFormScreen({super.key, this.initial});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  late final TextEditingController _nameController;
  late TransactionType _type;
  late String _icon;
  late int _color;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  static const _palette = [
    0xFFE53935, 0xFFD81B60, 0xFF8E24AA, 0xFF5E35B1,
    0xFF3949AB, 0xFF1E88E5, 0xFF039BE5, 0xFF00ACC1,
    0xFF00897B, 0xFF43A047, 0xFF7CB342, 0xFFC0CA33,
    0xFFFDD835, 0xFFFFB300, 0xFFFB8C00, 0xFFF4511E,
    0xFF6D4C41, 0xFF546E7A, 0xFF78909C, 0xFF2E7D32,
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController =
        TextEditingController(text: initial?.name ?? '');
    _type = initial?.type ?? TransactionType.expense;
    _icon = initial?.icon ?? 'category';
    _color = initial?.color ?? _palette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('Enter a name.');
      return;
    }
    setState(() => _saving = true);
    final state = context.read<AppState>();
    if (_isEdit) {
      await state.updateCategory(widget.initial!.copyWith(
        name: name,
        icon: _icon,
        color: _color,
      ));
    } else {
      await state.addCategory(Category(
        name: name,
        type: _type,
        icon: _icon,
        color: _color,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icons = availableIcons();
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit category' : 'New category')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofocus: !_isEdit,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Coffee',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isEdit) ...[
              const Text(
                'Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) =>
                    setState(() => _type = selection.first),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Icon',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                final icon = icons[index];
                final selected = _icon == iconNameFor(icon);
                return IconButton(
                  onPressed: () =>
                      setState(() => _icon = _nameFor(icon) ?? 'category'),
                  style: IconButton.styleFrom(
                    backgroundColor: selected
                        ? scheme.primary.withValues(alpha: 0.15)
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    foregroundColor:
                        selected ? scheme.primary : scheme.onSurface,
                    side: selected
                        ? BorderSide(color: scheme.primary, width: 2)
                        : null,
                  ),
                  icon: Icon(icon, size: 22),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Color',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in _palette)
                  InkWell(
                    onTap: () => setState(() => _color = color),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: _color == color
                            ? Border.all(
                                color: scheme.onSurface,
                                width: 2.5,
                              )
                            : null,
                      ),
                      child: _color == color
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: Text(_isEdit ? 'Save changes' : 'Add category'),
            ),
          ],
        ),
      ),
    );
  }

  String? _nameFor(IconData icon) => iconNameFor(icon);
}