import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/generated/l10n.dart';
import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/database/database_helper.dart';
import 'package:expense_tracker/services/ai_service.dart';
import 'package:expense_tracker/providers/theme_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AIService _aiService = AIService();
  final TextEditingController _budgetAmountController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  Category? _selectedCategory;
  String? _selectedMonth;
  bool _isLoadingSuggestions = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _refreshBudgets();
    _refreshCategories();
    _dbHelper.debugDatabase();
  }

  @override
  void dispose() {
    _budgetAmountController.dispose();
    _categoryNameController.dispose();
    _goalController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshBudgets() async {
    try {
      final budgets = await _dbHelper.getBudgets();
      if (mounted) {
        setState(() {
          _budgets = budgets;
        });
      }
    } catch (e) {
      print('Error refreshing budgets: $e');
    }
  }

  Future<void> _refreshCategories() async {
    try {
      final categories = await _dbHelper.getCategories();
      print('Categories loaded: ${categories.map((c) => c.id).toList()}');
      if (mounted) {
        setState(() {
          _categories = categories;
          _selectedCategory = categories.isNotEmpty ? categories[0] : null;
        });
      }
    } catch (e) {
      print('Error refreshing categories: $e');
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: l10n.chooseMonth,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
      });
    }
  }

  Future<bool> _budgetExists(int categoryId, String month) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'budgets',
        where: 'category_id = ? AND month = ?',
        whereArgs: [categoryId, month],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking budget existence: $e');
      return false;
    }
  }

  void _addBudget(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    if (_budgetAmountController.text.isEmpty || _selectedCategory == null || _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAllFields, style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
      return;
    }

    final amount = double.tryParse(_budgetAmountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.amountPositive, style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
      return;
    }

    final db = await _dbHelper.database;
    final categoryExists = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [_selectedCategory!.id!],
    );
    if (categoryExists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidCategorySelected, style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
      return;
    }

    if (await _budgetExists(_selectedCategory!.id!, _selectedMonth!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.budgetExists(_selectedCategory!.name, _selectedMonth!),
              style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
      return;
    }

    final budget = Budget(
      categoryId: _selectedCategory!.id!,
      month: _selectedMonth!,
      amount: amount,
      goal: _goalController.text.isEmpty ? null : _goalController.text,
    );

    try {
      final id = await _dbHelper.insertBudget(budget);
      if (id > 0) {
        _budgetAmountController.clear();
        _goalController.clear();
        if (mounted) {
          setState(() {
            _selectedMonth = null;
          });
        }
        await _refreshBudgets();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.budgetAdded(_selectedMonth!), style: const TextStyle(color: Colors.white)),
            backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToAddBudget, style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
      }
    } catch (e) {
      print('Error adding budget: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToAddBudget, style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
    }
  }

  void _editBudget(BuildContext context, Budget budget) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    _budgetAmountController.text = budget.amount.toString();
    _goalController.text = budget.goal ?? '';
    if (mounted) {
      setState(() {
        _selectedCategory = _categories.firstWhere(
          (cat) => cat.id == budget.categoryId,
          orElse: () => Category(id: 0, name: 'Unknown'),
        );
        _selectedMonth = budget.month;
      });
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [const Color(0xFF263238), const Color(0xFF37474F)]
                    : [Colors.white, const Color(0xFFE1F5FE)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    l10n.editBudget,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        '${l10n.category}: ${_selectedCategory!.name}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${l10n.month}: $_selectedMonth',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _budgetAmountController,
                        decoration: InputDecoration(
                          labelText: l10n.budgetAmount,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _goalController,
                        decoration: InputDecoration(
                          labelText: l10n.budgetGoal,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          final amount = double.tryParse(_budgetAmountController.text) ?? 0.0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(l10n.amountPositive, style: const TextStyle(color: Colors.white)),
                                backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                              ),
                            );
                            return;
                          }

                          final updatedBudget = Budget(
                            id: budget.id,
                            categoryId: budget.categoryId,
                            month: budget.month,
                            amount: amount,
                            goal: _goalController.text.isEmpty ? null : _goalController.text,
                          );

                          try {
                            final rowsAffected = await _dbHelper.updateBudget(updatedBudget);
                            if (rowsAffected > 0) {
                              _budgetAmountController.clear();
                              _goalController.clear();
                              if (mounted) {
                                setState(() {
                                  _selectedMonth = null;
                                });
                              }
                              await _refreshBudgets();
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.budgetUpdated, style: const TextStyle(color: Colors.white)),
                                  backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.failedToUpdateBudget,
                                      style: const TextStyle(color: Colors.white)),
                                  backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                                ),
                              );
                            }
                          } catch (e) {
                            print('Error updating budget: $e');
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(l10n.failedToUpdateBudget,
                                    style: const TextStyle(color: Colors.white)),
                                backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                              ),
                            );
                          }
                        },
                        child: Text(
                          l10n.save,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteBudget(BuildContext context, int id) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    try {
      _dbHelper.deleteBudget(id).then((rowsAffected) {
        if (rowsAffected > 0) {
          _refreshBudgets();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.budgetDeleted, style: const TextStyle(color: Colors.white)),
              backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToDeleteBudget, style: const TextStyle(color: Colors.white)),
              backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
            ),
          );
        }
      });
    } catch (e) {
      print('Error deleting budget: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToDeleteBudget, style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
    }
  }

  void _addCategory(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    if (_categoryNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.categoryEmpty, style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
      return;
    }

    final newCategoryName = _categoryNameController.text.trim();
    if (_categories.any((cat) => cat.name.toLowerCase() == newCategoryName.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.categoryExists, style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
      return;
    }

    _dbHelper.insertCategory(newCategoryName).then((_) {
      _refreshCategories();
      _categoryNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.categoryAdded(newCategoryName), style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
    });
  }

  Future<void> _suggestBudgets(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    if (mounted) {
      setState(() {
        _isLoadingSuggestions = true;
      });
    }

    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final suggestions = await _aiService.suggestBudgets(currentMonth);

    if (mounted) {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }

    if (suggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noBudgetSuggestions, style: const TextStyle(color: Colors.white)),
          backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [const Color(0xFF263238), const Color(0xFF37474F)]
                    : [Colors.white, const Color(0xFFE1F5FE)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    l10n.budgetSuggestions,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                    ),
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: suggestions.map((suggestion) {
                        final category = _categories.firstWhere(
                          (cat) => cat.id == suggestion['categoryId'],
                          orElse: () => Category(id: 0, name: 'Unknown'),
                        );
                        return ListTile(
                          title: Text(
                            '${category.name}: ₹${suggestion['amount'].toStringAsFixed(0)}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            suggestion['explanation'],
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          for (var suggestion in suggestions) {
                            if (!await _budgetExists(suggestion['categoryId'], currentMonth)) {
                              final budget = Budget(
                                categoryId: suggestion['categoryId'],
                                month: currentMonth,
                                amount: suggestion['amount'].toDouble(),
                                goal: null,
                              );
                              await _dbHelper.insertBudget(budget);
                            }
                          }
                          _refreshBudgets();
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(l10n.budgetsAdded, style: const TextStyle(color: Colors.white)),
                              backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                            ),
                          );
                        },
                        child: Text(
                          l10n.acceptAll,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDarkMode = Provider.of<ThemeProvider>(dialogContext).isDarkMode;
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [const Color(0xFF263238), const Color(0xFF37474F)]
                    : [Colors.white, const Color(0xFFE1F5FE)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    l10n.addCategory,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _categoryNameController,
                    decoration: InputDecoration(
                      labelText: l10n.categoryName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _addCategory(dialogContext);
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          l10n.add,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddBudgetDialog() {
    final l10n = AppLocalizations.of(context)!;
    _budgetAmountController.clear();
    _goalController.clear();
    if (mounted) {
      setState(() {
        _selectedMonth = null;
        _selectedCategory = _categories.isNotEmpty ? _categories[0] : null;
      });
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDarkMode = Provider.of<ThemeProvider>(dialogContext).isDarkMode;
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [const Color(0xFF263238), const Color(0xFF37474F)]
                    : [Colors.white, const Color(0xFFE1F5FE)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (dialogContext, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        l10n.addBudget,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          DropdownButton<Category>(
                            value: _selectedCategory,
                            hint: Text(
                              l10n.selectCategory,
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                              size: 20,
                            ),
                            items: _categories.map((Category category) {
                              return DropdownMenuItem<Category>(
                                value: category,
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (Category? newValue) {
                              setDialogState(() {
                                _selectedCategory = newValue;
                              });
                            },
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            dropdownColor: isDarkMode ? const Color(0xFF263238) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _budgetAmountController,
                            decoration: InputDecoration(
                              labelText: l10n.budgetAmount,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _goalController,
                            decoration: InputDecoration(
                              labelText: l10n.budgetGoal,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedMonth == null
                                      ? l10n.noMonthChosen
                                      : '${l10n.chooseMonth}: $_selectedMonth',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  await _selectMonth(dialogContext);
                                  setDialogState(() {});
                                },
                                child: Text(
                                  l10n.chooseMonth,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(dialogContext);
                            },
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              _addBudget(dialogContext);
                              Navigator.pop(dialogContext);
                            },
                            child: Text(
                              l10n.add,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 5,
                      shadowColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? [const Color(0xFF263238), const Color(0xFF37474F)]
                                : [Colors.white, const Color(0xFFE1F5FE)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButton<Category>(
                                      value: _selectedCategory,
                                      hint: Text(
                                        l10n.selectCategory,
                                        style: const TextStyle(fontFamily: 'Poppins'),
                                      ),
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                                        size: 20,
                                      ),
                                      items: _categories.map((Category category) {
                                        return DropdownMenuItem<Category>(
                                          value: category,
                                          child: Text(
                                            category.name,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (Category? newValue) {
                                        HapticFeedback.mediumImpact();
                                        if (mounted) {
                                          setState(() {
                                            _selectedCategory = newValue;
                                          });
                                        }
                                      },
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                      dropdownColor: isDarkMode ? const Color(0xFF263238) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle,
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
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      _showAddCategoryDialog();
                                    },
                                    tooltip: l10n.addCategory,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _budgetAmountController,
                                decoration: InputDecoration(
                                  labelText: l10n.budgetAmount,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _goalController,
                                decoration: InputDecoration(
                                  labelText: l10n.budgetGoal,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedMonth == null
                                          ? l10n.noMonthChosen
                                          : '${l10n.chooseMonth}: $_selectedMonth',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      _selectMonth(context);
                                    },
                                    child: Text(
                                      l10n.chooseMonth,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      _addBudget(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(100, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isDarkMode
                                              ? [Colors.teal[700]!, Colors.teal[500]!]
                                              : [Colors.teal[600]!, Colors.teal[400]!],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Text(
                                        l10n.addBudget,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _isLoadingSuggestions
                                        ? null
                                        : () {
                                            HapticFeedback.mediumImpact();
                                            _suggestBudgets(context);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(100, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isDarkMode
                                              ? [Colors.teal[700]!, Colors.teal[500]!]
                                              : [Colors.teal[600]!, Colors.teal[400]!],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: _isLoadingSuggestions
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              l10n.suggestBudgets,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 5,
                      shadowColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? [const Color(0xFF263238), const Color(0xFF37474F)]
                                : [Colors.white, const Color(0xFFE1F5FE)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.currentBudgets,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _budgets.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: Text(
                                        l10n.noBudgets,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _budgets.length,
                                      itemBuilder: (context, index) {
                                        final budget = _budgets[index];
                                        final category = _categories.firstWhere(
                                          (cat) => cat.id == budget.categoryId,
                                          orElse: () => Category(id: 0, name: 'Unknown'),
                                        );
                                        return FutureBuilder<double>(
                                          future: _dbHelper.getSpendingForCategoryAndMonth(
                                              budget.categoryId, budget.month),
                                          builder: (context, snapshot) {
                                            final spending = snapshot.data ?? 0.0;
                                            final progress = budget.amount > 0 ? spending / budget.amount : 0.0;
                                            final isOverBudget = spending > budget.amount;
                                            return Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(12),
                                                onTap: () {
                                                  HapticFeedback.mediumImpact();
                                                  _editBudget(context, budget);
                                                },
                                                splashColor: isDarkMode
                                                    ? Colors.teal[400]!.withOpacity(0.3)
                                                    : Colors.teal[600]!.withOpacity(0.3),
                                                child: ListTile(
                                                  title: Text(
                                                    '${category.name} (${budget.month})',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDarkMode ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Budget: ₹${budget.amount.toStringAsFixed(2)} | Spent: ₹${spending.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 13,
                                                          color: isOverBudget
                                                              ? isDarkMode
                                                                  ? Colors.red[400]
                                                                  : Colors.red[600]
                                                              : isDarkMode
                                                                  ? Colors.grey[400]
                                                                  : Colors.grey[600],
                                                        ),
                                                      ),
                                                      if (budget.goal != null)
                                                        Text(
                                                          'Goal: ${budget.goal}',
                                                          style: TextStyle(
                                                            fontFamily: 'Poppins',
                                                            fontSize: 13,
                                                            color: isDarkMode
                                                                ? Colors.grey[400]
                                                                : Colors.grey[600],
                                                          ),
                                                        ),
                                                      const SizedBox(height: 4),
                                                      LinearProgressIndicator(
                                                        value: progress > 1 ? 1 : progress,
                                                        color: isOverBudget
                                                            ? isDarkMode
                                                                ? Colors.red[400]
                                                                : Colors.red[600]
                                                            : isDarkMode
                                                                ? Colors.teal[400]
                                                                : Colors.teal[600],
                                                        backgroundColor: isDarkMode
                                                            ? Colors.grey[700]
                                                            : Colors.grey[300],
                                                        minHeight: 4,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ],
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.edit,
                                                          color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                                                          size: 26,
                                                          shadows: [
                                                            Shadow(
                                                              blurRadius: 2,
                                                              color: isDarkMode
                                                                  ? Colors.black26
                                                                  : Colors.grey[300]!,
                                                              offset: const Offset(1, 1),
                                                            ),
                                                          ],
                                                        ),
                                                        onPressed: () {
                                                          HapticFeedback.mediumImpact();
                                                          _editBudget(context, budget);
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.delete,
                                                          color: isDarkMode ? Colors.red[400] : Colors.red[600],
                                                          size: 26,
                                                          shadows: [
                                                            Shadow(
                                                              blurRadius: 2,
                                                              color: isDarkMode
                                                                  ? Colors.black26
                                                                  : Colors.grey[300]!,
                                                              offset: const Offset(1, 1),
                                                            ),
                                                          ],
                                                        ),
                                                        onPressed: () {
                                                          HapticFeedback.mediumImpact();
                                                          _deleteBudget(context, budget.id!);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ],
                          ),
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
}