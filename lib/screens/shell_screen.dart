import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/app_background.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final body = switch (_index) {
      0 => DashboardScreen(
          onSeeAllTransactions: () => setState(() => _index = 1),
          onSeeAllInsights: () => setState(() => _index = 2),
        ),
      1 => const TransactionsScreen(),
      2 => const AnalyticsScreen(),
      _ => const SettingsScreen(),
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(_titles[_index])),
          body: body,
          floatingActionButton: _index <= 1
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary,
                        AppTheme.accentIndigo,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TransactionFormScreen(),
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    highlightElevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                )
              : null,
          bottomNavigationBar: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                backgroundColor: isDark
                    ? const Color(0xE61E1E1E)
                    : Colors.white.withValues(alpha: 0.78),
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
            ),
          ),
        ),
      ],
    );
  }
}