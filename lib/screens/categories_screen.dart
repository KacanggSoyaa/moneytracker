import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/app_state.dart';
import '../widgets/category_avatar.dart';
import 'category_form_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _Section(
            title: 'Income',
            categories: state.incomeCategories,
            onEdit: (c) => _openCategoryForm(context, c),
            onDelete: (c) => _confirmDelete(context, state, c),
          ),
          _Section(
            title: 'Expense',
            categories: state.expenseCategories,
            onEdit: (c) => _openCategoryForm(context, c),
            onDelete: (c) => _confirmDelete(context, state, c),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New category'),
      ),
    );
  }
}

void _openCategoryForm(BuildContext context, Category? category) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CategoryFormScreen(initial: category),
    ),
  );
}

Future<void> _confirmDelete(
    BuildContext context, AppState state, Category category) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete category'),
      content: Text('Delete "${category.name}"?'),
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
  try {
    await state.deleteCategory(category);
  } on StateError catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Category> categories;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  const _Section({
    required this.title,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (var i = 0; i < categories.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 72),
                ListTile(
                  leading: CategoryAvatar(category: categories[i]),
                  title: Text(
                    categories[i].name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => onEdit(categories[i]),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    tooltip: 'Delete',
                    onPressed: () => onDelete(categories[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}