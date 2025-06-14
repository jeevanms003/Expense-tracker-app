import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/generated/l10n.dart';
import 'package:expense_tracker/database/database_helper.dart';
import 'package:expense_tracker/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLanguageChanged;

  const SettingsScreen({required this.onLanguageChanged, super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  String _selectedLanguage = 'en';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final language = await _dbHelper.getLanguage();
    setState(() {
      _selectedLanguage = language;
    });
  }

  Future<void> _changeLanguage(String language) async {
    HapticFeedback.mediumImpact();
    await _dbHelper.setLanguage(language);
    setState(() {
      _selectedLanguage = language;
    });
    widget.onLanguageChanged();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent, // Let gradient show through
      body: Container(
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 5,
                      shadowColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
                                : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildListTile(
                              context: context,
                              icon: Icons.dark_mode,
                              title: l10n.darkMode,
                              trailing: Transform.scale(
                                scale: 0.9,
                                child: Switch(
                                  value: themeProvider.isDarkMode,
                                  onChanged: (value) {
                                    HapticFeedback.mediumImpact();
                                    themeProvider.toggleTheme();
                                    _animationController.reset();
                                    _animationController.forward();
                                  },
                                  activeColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                                  activeTrackColor:
                                      isDarkMode ? Colors.teal[400]!.withOpacity(0.5) : Colors.teal[600]!.withOpacity(0.5),
                                  inactiveThumbColor: Colors.grey[400],
                                  inactiveTrackColor: Colors.grey[600],
                                ),
                              ),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                themeProvider.toggleTheme();
                                _animationController.reset();
                                _animationController.forward();
                              },
                            ),
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              thickness: 0.5,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                            ),
                            _buildListTile(
                              context: context,
                              icon: Icons.translate,
                              title: l10n.language,
                              trailing: DropdownButton<String>(
                                value: _selectedLanguage,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                                  size: 20,
                                ),
                                underline: const SizedBox(),
                                items: [
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Text(
                                      l10n.english,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'hi',
                                    child: Text(
                                      l10n.hindi,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'kn',
                                    child: Text(
                                      l10n.kannada,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    _changeLanguage(value);
                                  }
                                },
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                                dropdownColor: isDarkMode ? const Color(0xFF2E2E2E) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        splashColor: isDarkMode ? Colors.teal[400]!.withOpacity(0.3) : Colors.teal[600]!.withOpacity(0.3),
        child: ListTile(
          leading: Icon(
            icon,
            color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
            size: 26,
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
              fontWeight: FontWeight.w700, // Bold for titles
              color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
            ),
          ),
          trailing: trailing,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minVerticalPadding: 0,
        ),
      ),
    );
  }
}