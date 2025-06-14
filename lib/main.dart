import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/generated/l10n.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'widgets/home_content.dart';
import 'widgets/budget_screen.dart';
import 'widgets/reports_content.dart';
import 'widgets/settings_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/chatbot_screen.dart';
import 'database/database_helper.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  _ExpenseTrackerAppState createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  Locale _locale = const Locale('en');
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final language = await _dbHelper.getLanguage();
    setState(() {
      _locale = Locale(language);
    });
  }

  void _onLanguageChanged() {
    _loadLocale();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Expense Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('hi', ''),
        Locale('kn', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MainPage(onLanguageChanged: _onLanguageChanged),
    );
  }
}

class MainPage extends StatefulWidget {
  final VoidCallback onLanguageChanged;

  const MainPage({required this.onLanguageChanged, super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _currentPage = 'home';

  void _showChatbot() {
    showDialog(
      context: context,
      builder: (context) => const ChatbotScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentPage == 'home'
              ? l10n.appTitle
              : _currentPage == 'budgets'
                  ? l10n.budgets
                  : _currentPage == 'reports'
                      ? l10n.reports
                      : l10n.settings,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: _showChatbot,
            tooltip: 'AI Assistant',
          ),
        ],
      ),
      drawer: AppDrawer(
        onPageSelected: (page) {
          setState(() {
            _currentPage = page;
          });
        },
      ),
      body: _currentPage == 'home'
          ? const HomeContent()
          : _currentPage == 'budgets'
              ? const BudgetScreen()
              : _currentPage == 'reports'
                  ? const ReportsContent()
                  : SettingsScreen(onLanguageChanged: widget.onLanguageChanged),
    );
  }
}