import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/generated/l10n.dart';
import 'package:expense_tracker/providers/theme_provider.dart';

class AppDrawer extends StatelessWidget {
  final Function(String) onPageSelected;

  const AppDrawer({required this.onPageSelected, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                : [const Color(0xFFE8F5E9), const Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            physics: const BouncingScrollPhysics(),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
                        : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: isDarkMode ? Colors.teal[200] : Colors.teal[300], // Changed from Colors.white
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              _buildDrawerItem(
                context: context,
                icon: Icons.home,
                title: l10n.home,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onPageSelected('home');
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.account_balance_wallet,
                title: l10n.budgets,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onPageSelected('budgets');
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.bar_chart,
                title: l10n.reports,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onPageSelected('reports');
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.settings,
                title: l10n.settings,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onPageSelected('settings');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: isDarkMode ? Colors.teal[400]!.withOpacity(0.3) : Colors.teal[600]!.withOpacity(0.3),
        child: ListTile(
          leading: Icon(
            icon,
            color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
            size: 28,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: isDarkMode ? Colors.black26 : Colors.grey[300]!,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500, // Medium
              color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minVerticalPadding: 0,
        ),
      ),
    );
  }
}