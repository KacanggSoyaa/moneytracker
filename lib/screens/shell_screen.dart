import 'package:flutter/material.dart';

import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'transaction_form_screen.dart';
import 'transactions_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const _titles = ['Money Tracker', 'Transactions', 'Insights', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final body = switch (_index) {
      0 => DashboardScreen(
          onSeeAllTransactions: () => setState(() => _index = 1),
          onSeeAllInsights: () => setState(() => _index = 2),
        ),
      1 => const TransactionsScreen(),
      2 => const AnalyticsScreen(),
      _ => const SettingsScreen(),
    };
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: body,
      floatingActionButton: _index <= 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TransactionFormScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}