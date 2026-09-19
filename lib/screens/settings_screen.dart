import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../providers/app_state.dart';
import '../services/csv_service.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportCsv() async {
    try {
      final path = await CsvService.export(AppDatabase.instance);
      if (!mounted) return;
      _snack(path == null ? 'Export canceled.' : 'Backup saved to $path');
    } catch (e) {
      _snack('Export failed: $e');
    }
  }

  Future<void> _pickTheme() {
    final state = context.read<AppState>();
    return showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: state.settings.themeMode,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(_themeLabel(mode)),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).then((mode) {
      if (mode != null) state.setThemeMode(mode);
    });
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Auto (follow system)',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  Future<void> _pickCurrency() {
    final state = context.read<AppState>();
    final currencies = [
      (r'$', 'US Dollar'),
      ('€', 'Euro'),
      ('£', 'British Pound'),
      ('¥', 'Japanese Yen'),
      ('Rp', 'Indonesian Rupiah'),
      ('₹', 'Indian Rupee'),
      ('₩', 'Korean Won'),
      ('CHF', 'Swiss Franc'),
      (r'A$', 'Australian Dollar'),
      (r'C$', 'Canadian Dollar'),
      (r'R$', 'Brazilian Real'),
      ('₱', 'Philippine Peso'),
      ('RM', 'Malaysian Ringgit'),
      ('₫', 'Vietnamese Dong'),
      ('฿', 'Thai Baht'),
      (r'₺', 'Turkish Lira'),
      ('AED', 'UAE Dirham'),
      (r'S$', 'Singapore Dollar'),
    ];
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Currency'),
        children: [
          for (final (symbol, name) in currencies)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(symbol),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      symbol,
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(name),
                  if (state.settings.currencySymbol == symbol)
                    const Spacer(),
                  if (state.settings.currencySymbol == symbol)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
        ],
      ),
    ).then((symbol) async {
      if (symbol != null) {
        await state.setCurrencySymbol(symbol);
        _snack('Currency set to $symbol');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _Header(
          title: 'Appearance',
          icon: Icons.palette_outlined,
          color: scheme.primary,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Theme'),
                subtitle: Text(_themeLabel(state.settings.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickTheme(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Currency'),
                subtitle: Text(state.settings.currencySymbol),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickCurrency,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _Header(
          title: 'Categories',
          icon: Icons.category_outlined,
          color: scheme.primary,
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bookmarks_outlined),
            title: const Text('Manage categories'),
            subtitle: const Text('Add, edit or delete your own categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _Header(
          title: 'Data',
          icon: Icons.storage_outlined,
          color: scheme.primary,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: const Text('Export backup (CSV)'),
                subtitle: const Text('Save all transactions to a file'),
                onTap: _exportCsv,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Import backup (CSV)'),
                subtitle: const Text('Restore transactions from a file'),
                onTap: () => _importCsv(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Text(
                'Money Tracker',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _version.isEmpty ? 'Version loading…' : 'Version $_version',
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
              const SizedBox(height: 2),
              Text(
                'Your data stays on this device.',
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result.isEmpty) return;
    try {
      final bytes = await result.single.readAsBytes();
      final outcome = await CsvService.import(AppDatabase.instance, bytes);
      if (!mounted) return;
      await context.read<AppState>().refresh();
      _snack('Imported ${outcome.imported} transaction(s).');
    } catch (e) {
      _snack('Import failed: $e');
    }
  }
}

class _Header extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _Header({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}