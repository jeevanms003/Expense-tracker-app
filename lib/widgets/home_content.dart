import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/generated/l10n.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/database/database_helper.dart';
import 'package:expense_tracker/services/ai_service.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TransactionFilter {
  String? searchQuery;
  List<int> categoryIds;
  List<int> paymentMethodIds;
  DateTime? startDate;
  DateTime? endDate;
  double? minAmount;
  double? maxAmount;

  TransactionFilter({
    this.searchQuery,
    this.categoryIds = const [],
    this.paymentMethodIds = const [],
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  bool isActive() {
    return searchQuery != null ||
        categoryIds.isNotEmpty ||
        paymentMethodIds.isNotEmpty ||
        startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null;
  }

  void reset() {
    searchQuery = null;
    categoryIds = [];
    paymentMethodIds = [];
    startDate = null;
    endDate = null;
    minAmount = null;
    maxAmount = null;
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AIService _aiService = AIService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  DateTime? _selectedDate;
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Budget> _budgets = [];
  List<PaymentMethod> _paymentMethods = [];
  Category? _selectedCategory;
  PaymentMethod? _selectedPaymentMethod;
  bool _isSuggesting = false;
  bool _isListening = false;
  String _voiceTranscript = '';
  bool _showTranscriptDialog = false;
  TransactionFilter _filter = TransactionFilter();
  String _currentLocale = 'en';
  int _speechRetryCount = 0;
  static const int _maxSpeechRetries = 2;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadLocale();
    _initializeSpeech();
    _refreshTransactions();
    _refreshCategories();
    _refreshBudgets();
    _refreshPaymentMethods();
    _searchController.addListener(_applyFilters);
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
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLocale() async {
    final language = await _dbHelper.getLanguage();
    setState(() {
      _currentLocale = language;
    });
  }

  Future<void> _initializeSpeech() async {
    final l10n = AppLocalizations.of(context)!;
    String speechLocale;
    switch (_currentLocale) {
      case 'hi':
        speechLocale = 'hi_IN';
        break;
      case 'kn':
        speechLocale = 'kn_IN';
        break;
      default:
        speechLocale = 'en_IN';
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        setState(() {
          _isListening = status == 'listening';
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            if (_voiceTranscript.isNotEmpty && _speechRetryCount <= _maxSpeechRetries) {
              _processVoiceInput();
            } else {
              _showTranscriptDialog = false;
              _speechRetryCount = 0;
            }
          }
        });
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _showTranscriptDialog = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.speechError(error.errorMsg),
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (_speechRetryCount < _maxSpeechRetries) {
          _speechRetryCount++;
          _startListening();
        } else {
          _speechRetryCount = 0;
        }
      },
    );
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.speechNotAvailable,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _startListening() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_speech.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.speechNotAvailable,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isListening = true;
      _voiceTranscript = '';
      _showTranscriptDialog = true;
    });

    String speechLocale;
    switch (_currentLocale) {
      case 'hi':
        speechLocale = 'hi_IN';
        break;
      case 'kn':
        speechLocale = 'kn_IN';
        break;
      default:
        speechLocale = 'en_IN';
    }

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _voiceTranscript = result.recognizedWords;
        });
      },
      localeId: speechLocale,
      partialResults: true,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 5),
      cancelOnError: true,
    );
  }

  Future<void> _processVoiceInput() async {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    setState(() {
      _isListening = false;
      _voiceTranscript = _voiceTranscript.trim();
    });

    if (_voiceTranscript.isEmpty) {
      setState(() {
        _showTranscriptDialog = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.noSpeechDetected,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _showTranscriptDialog = false;
    });

    await _speech.stop();

    final transactionDetails = await _aiService.parseVoiceTransaction(_voiceTranscript);
    final suggestedCategory = _categories.firstWhere(
      (cat) => cat.id == transactionDetails['categoryId'],
      orElse: () => _categories.isNotEmpty ? _categories[0] : Category(id: 1, name: 'Unknown'),
    );
    final suggestedPaymentMethod = _paymentMethods.firstWhere(
      (pm) => pm.id == transactionDetails['paymentMethodId'],
      orElse: () => _paymentMethods.isNotEmpty ? _paymentMethods[0] : PaymentMethod(id: 1, name: 'Unknown'),
    );
    final confidence = transactionDetails['confidence'] as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => FadeTransition(
        opacity: _fadeAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            l10n.confirmTransaction,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[900],
            ),
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final titleController = TextEditingController(text: transactionDetails['title']);
                final amountController = TextEditingController(text: transactionDetails['amount'].toString());
                DateTime? selectedDate = DateTime.parse(transactionDetails['date']);
                Category? selectedCategory = suggestedCategory;
                PaymentMethod? selectedPaymentMethod = suggestedPaymentMethod;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: titleController,
                      label: l10n.title,
                      helperText: 'Confidence: ${(confidence['title'] * 100).toStringAsFixed(0)}%',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: amountController,
                      label: l10n.amount,
                      helperText: 'Confidence: ${(confidence['amount'] * 100).toStringAsFixed(0)}%',
                      isDarkMode: isDarkMode,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerRow(
                      context: context,
                      selectedDate: selectedDate,
                      onDateSelected: (picked) => setDialogState(() => selectedDate = picked),
                      isDarkMode: isDarkMode,
                      label: l10n.chooseDate,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<Category>(
                      value: selectedCategory,
                      hint: '${l10n.selectCategory} (Confidence: ${(confidence['categoryId'] * 100).toStringAsFixed(0)}%)',
                      items: _categories,
                      onChanged: (newValue) => setDialogState(() => selectedCategory = newValue),
                      isDarkMode: isDarkMode,
                      itemBuilder: (item) => item.name,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<PaymentMethod>(
                      value: selectedPaymentMethod,
                      hint: '${l10n.selectPaymentMethod} (Confidence: ${(confidence['paymentMethodId'] * 100).toStringAsFixed(0)}%)',
                      items: _paymentMethods,
                      onChanged: (newValue) => setDialogState(() => selectedPaymentMethod = newValue),
                      isDarkMode: isDarkMode,
                      itemBuilder: (item) => item.name,
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                setState(() {
                  _voiceTranscript = '';
                  _showTranscriptDialog = false;
                  _speechRetryCount = 0;
                });
              },
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.amber[400] : Colors.deepPurple[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final titleController = TextEditingController(text: transactionDetails['title']);
                final amountController = TextEditingController(text: transactionDetails['amount'].toString());
                DateTime? selectedDate = DateTime.parse(transactionDetails['date']);
                Category? selectedCategory = suggestedCategory;
                PaymentMethod? selectedPaymentMethod = suggestedPaymentMethod;

                if (titleController.text.isEmpty ||
                    amountController.text.isEmpty ||
                    selectedDate == null ||
                    selectedCategory == null ||
                    selectedPaymentMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.fillAllFields,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.amountPositive,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return;
                }

                final transaction = Transaction(
                  title: titleController.text,
                  amount: amount,
                  date: selectedDate,
                  categoryId: selectedCategory!.id!,
                  paymentMethodId: selectedPaymentMethod!.id!,
                );

                await _dbHelper.insertTransaction(transaction);
                await _refreshTransactions();
                await _refreshBudgets();

                setState(() {
                  _voiceTranscript = '';
                  _showTranscriptDialog = false;
                  _speechRetryCount = 0;
                });
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.transactionAdded,
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                    ),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.teal[700] : Colors.teal[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                l10n.confirm,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshTransactions() async {
    final transactions = await _dbHelper.getTransactions(
      searchQuery: _filter.searchQuery,
      categoryIds: _filter.categoryIds,
      paymentMethodIds: _filter.paymentMethodIds,
      startDate: _filter.startDate,
      endDate: _filter.endDate,
      minAmount: _filter.minAmount,
      maxAmount: _filter.maxAmount,
    );
    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _refreshCategories() async {
    final categories = await _dbHelper.getCategories();
    setState(() {
      _categories = categories;
      _selectedCategory = categories.isNotEmpty ? categories[0] : null;
    });
  }

  Future<void> _refreshBudgets() async {
    final budgets = await _dbHelper.getBudgets();
    setState(() {
      _budgets = budgets;
    });
  }

  Future<void> _refreshPaymentMethods() async {
    final paymentMethods = await _dbHelper.getPaymentMethods();
    setState(() {
      _paymentMethods = paymentMethods;
      _selectedPaymentMethod = paymentMethods.isNotEmpty ? paymentMethods[0] : null;
    });
  }

  Future<void> _suggestTransactionDetails() async {
    final l10n = AppLocalizations.of(context)!;
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.enterTitleToSuggest,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isSuggesting = true;
    });

    final suggestions = await _aiService.suggestTransactionDetails(_titleController.text);
    setState(() {
      _selectedCategory = _categories.firstWhere(
        (cat) => cat.id == suggestions['categoryId'],
        orElse: () => _categories.isNotEmpty ? _categories[0] : Category(id: 1, name: 'Unknown'),
      );
      _selectedPaymentMethod = _paymentMethods.firstWhere(
        (pm) => pm.id == suggestions['paymentMethodId'],
        orElse: () => _paymentMethods.isNotEmpty ? _paymentMethods[0] : PaymentMethod(id: 1, name: 'Unknown'),
      );
      _isSuggesting = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: l10n.chooseDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
            ),
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).brightness == Brightness.dark ? Colors.teal[400]! : Colors.teal[600]!,
              onPrimary: Colors.white,
              surface: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.white,
            ),
            dialogBackgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filter.searchQuery = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
    });
    _refreshTransactions();
  }

  void _showFilterDialog() {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    List<int> tempCategoryIds = List.from(_filter.categoryIds);
    List<int> tempPaymentMethodIds = List.from(_filter.paymentMethodIds);
    DateTime? tempStartDate = _filter.startDate;
    DateTime? tempEndDate = _filter.endDate;
    _minAmountController.text = _filter.minAmount?.toString() ?? '';
    _maxAmountController.text = _filter.maxAmount?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => FadeTransition(
        opacity: _fadeAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            l10n.filterTransactions,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[900],
            ),
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectCategory,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        return FilterChip(
                          label: Text(
                            cat.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          selected: tempCategoryIds.contains(cat.id),
                          onSelected: (selected) {
                            HapticFeedback.mediumImpact();
                            setDialogState(() {
                              if (selected) {
                                tempCategoryIds.add(cat.id!);
                              } else {
                                tempCategoryIds.remove(cat.id);
                              }
                            });
                          },
                          selectedColor: isDarkMode ? Colors.teal[700] : Colors.teal[100],
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.grey[900],
                          ),
                          checkmarkColor: isDarkMode ? Colors.white : Colors.teal[600],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.selectPaymentMethod,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paymentMethods.map((pm) {
                        return FilterChip(
                          label: Text(
                            pm.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          selected: tempPaymentMethodIds.contains(pm.id),
                          onSelected: (selected) {
                            HapticFeedback.mediumImpact();
                            setDialogState(() {
                              if (selected) {
                                tempPaymentMethodIds.add(pm.id!);
                              } else {
                                tempPaymentMethodIds.remove(pm.id);
                              }
                            });
                          },
                          selectedColor: isDarkMode ? Colors.teal[700] : Colors.teal[100],
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.grey[900],
                          ),
                          checkmarkColor: isDarkMode ? Colors.white : Colors.teal[600],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerRow(
                      context: context,
                      selectedDate: tempStartDate,
                      onDateSelected: (picked) => setDialogState(() => tempStartDate = picked),
                      isDarkMode: isDarkMode,
                      label: l10n.chooseDate,
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerRow(
                      context: context,
                      selectedDate: tempEndDate,
                      onDateSelected: (picked) => setDialogState(() => tempEndDate = picked),
                      isDarkMode: isDarkMode,
                      label: l10n.chooseDate,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _minAmountController,
                      label: l10n.minAmount,
                      isDarkMode: isDarkMode,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _maxAmountController,
                      label: l10n.maxAmount,
                      isDarkMode: isDarkMode,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.amber[400] : Colors.deepPurple[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _filter.categoryIds = tempCategoryIds;
                  _filter.paymentMethodIds = tempPaymentMethodIds;
                  _filter.startDate = tempStartDate;
                  _filter.endDate = tempEndDate;
                  _filter.minAmount = double.tryParse(_minAmountController.text) ?? null;
                  _filter.maxAmount = double.tryParse(_maxAmountController.text) ?? null;
                });
                _refreshTransactions();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.teal[700] : Colors.teal[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                l10n.apply,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    _titleController.text = transaction.title;
    _amountController.text = transaction.amount.toString();
    _selectedDate = transaction.date;
    _selectedCategory = _categories.firstWhere(
      (cat) => cat.id == transaction.categoryId,
      orElse: () => _categories.isNotEmpty ? _categories[0] : Category(id: 1, name: 'Unknown'),
    );
    _selectedPaymentMethod = _paymentMethods.firstWhere(
      (pm) => pm.id == transaction.paymentMethodId,
      orElse: () => _paymentMethods.isNotEmpty ? _paymentMethods[0] : PaymentMethod(id: 1, name: 'Unknown'),
    );

    showDialog(
      context: context,
      builder: (context) => FadeTransition(
        opacity: _fadeAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            l10n.editTransaction,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[900],
            ),
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: l10n.title,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _amountController,
                  label: l10n.amount,
                  isDarkMode: isDarkMode,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildDatePickerRow(
                  context: context,
                  selectedDate: _selectedDate,
                  onDateSelected: (picked) => setState(() => _selectedDate = picked),
                  isDarkMode: isDarkMode,
                  label: l10n.chooseDate,
                ),
                const SizedBox(height: 16),
                _buildDropdown<Category>(
                  value: _selectedCategory,
                  hint: l10n.selectCategory,
                  items: _categories,
                  onChanged: (newValue) => setState(() => _selectedCategory = newValue),
                  isDarkMode: isDarkMode,
                  itemBuilder: (item) => item.name,
                ),
                const SizedBox(height: 16),
                _buildDropdown<PaymentMethod>(
                  value: _selectedPaymentMethod,
                  hint: l10n.selectPaymentMethod,
                  items: _paymentMethods,
                  onChanged: (newValue) => setState(() => _selectedPaymentMethod = newValue),
                  isDarkMode: isDarkMode,
                  itemBuilder: (item) => item.name,
                ),
                const SizedBox(height: 16),
                _isSuggesting
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        icon: Icon(
                          Icons.lightbulb,
                          color: isDarkMode ? Colors.amber[400] : Colors.deepPurple[600],
                          size: 20,
                        ),
                        label: Text(
                          l10n.suggestDetails,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          foregroundColor: isDarkMode ? Colors.white : Colors.grey[900],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _suggestTransactionDetails,
                      ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                _titleController.clear();
                _amountController.clear();
                setState(() {
                  _selectedDate = null;
                  _selectedCategory = _categories.isNotEmpty ? _categories[0] : null;
                  _selectedPaymentMethod = _paymentMethods.isNotEmpty ? _paymentMethods[0] : null;
                });
              },
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.amber[400] : Colors.deepPurple[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                if (_titleController.text.isEmpty ||
                    _amountController.text.isEmpty ||
                    _selectedDate == null ||
                    _selectedCategory == null ||
                    _selectedPaymentMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.fillAllFields,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(_amountController.text) ?? 0.0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.amountPositive,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return;
                }

                final updatedTransaction = Transaction(
                  id: transaction.id,
                  title: _titleController.text,
                  amount: amount,
                  date: _selectedDate!,
                  categoryId: _selectedCategory!.id!,
                  paymentMethodId: _selectedPaymentMethod!.id!,
                );

                await _dbHelper.updateTransaction(updatedTransaction);
                await _refreshTransactions();
                await _refreshBudgets();

                _titleController.clear();
                _amountController.clear();
                setState(() {
                  _selectedDate = null;
                  _selectedCategory = _categories.isNotEmpty ? _categories[0] : null;
                  _selectedPaymentMethod = _paymentMethods.isNotEmpty ? _paymentMethods[0] : null;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.transactionUpdated,
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                    ),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.teal[700] : Colors.teal[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                l10n.save,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog() {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) => FadeTransition(
        opacity: _fadeAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            l10n.addTransaction,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[900],
            ),
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final localTitleController = TextEditingController();
                final localAmountController = TextEditingController();
                DateTime? localSelectedDate;
                Category? localSelectedCategory = _categories.isNotEmpty ? _categories[0] : null;
                PaymentMethod? localSelectedPaymentMethod = _paymentMethods.isNotEmpty ? _paymentMethods[0] : null;
                bool localIsSuggesting = false;

                Future<void> localSuggestTransactionDetails() async {
                  final l10n = AppLocalizations.of(context)!;
                  if (localTitleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.enterTitleToSuggest,
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    return;
                  }

                  setDialogState(() {
                    localIsSuggesting = true;
                  });

                  final suggestions = await _aiService.suggestTransactionDetails(localTitleController.text);
                  setDialogState(() {
                    localSelectedCategory = _categories.firstWhere(
                      (cat) => cat.id == suggestions['categoryId'],
                      orElse: () => _categories.isNotEmpty ? _categories[0] : Category(id: 1, name: 'Unknown'),
                    );
                    localSelectedPaymentMethod = _paymentMethods.firstWhere(
                      (pm) => pm.id == suggestions['paymentMethodId'],
                      orElse: () => _paymentMethods.isNotEmpty ? _paymentMethods[0] : PaymentMethod(id: 1, name: 'Unknown'),
                    );
                    localIsSuggesting = false;
                  });
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: localTitleController,
                      label: l10n.title,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: localAmountController,
                      label: l10n.amount,
                      isDarkMode: isDarkMode,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerRow(
                      context: context,
                      selectedDate: localSelectedDate,
                      onDateSelected: (picked) => setDialogState(() => localSelectedDate = picked),
                      isDarkMode: isDarkMode,
                      label: l10n.chooseDate,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<Category>(
                      value: localSelectedCategory,
                      hint: l10n.selectCategory,
                      items: _categories,
                      onChanged: (newValue) => setDialogState(() => localSelectedCategory = newValue),
                      isDarkMode: isDarkMode,
                      itemBuilder: (item) => item.name,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<PaymentMethod>(
                      value: localSelectedPaymentMethod,
                      hint: l10n.selectPaymentMethod,
                      items: _paymentMethods,
                      onChanged: (newValue) => setDialogState(() => localSelectedPaymentMethod = newValue),
                      isDarkMode: isDarkMode,
                      itemBuilder: (item) => item.name,
                    ),
                    const SizedBox(height: 16),
                    localIsSuggesting
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            icon: Icon(
                              Icons.lightbulb,
                              color: isDarkMode ? Colors.amber[400] : Colors.deepPurple[600],
                              size: 20,
                            ),
                            label: Text(
                              l10n.suggestDetails,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              foregroundColor: isDarkMode ? Colors.white : Colors.grey[900],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: localSuggestTransactionDetails,
                          ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.amber[400] : Colors.deepPurple[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final localTitleController = TextEditingController();
                final localAmountController = TextEditingController();
                DateTime? localSelectedDate;
                Category? localSelectedCategory = _categories.isNotEmpty ? _categories[0] : null;
                PaymentMethod? localSelectedPaymentMethod = _paymentMethods.isNotEmpty ? _paymentMethods[0] : null;

                if (localTitleController.text.isEmpty ||
                    localAmountController.text.isEmpty ||
                    localSelectedDate == null ||
                    localSelectedCategory == null ||
                    localSelectedPaymentMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.fillAllFields,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(localAmountController.text) ?? 0.0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.amountPositive,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return;
                }

                final transaction = Transaction(
                  title: localTitleController.text,
                  amount: amount,
                  date: localSelectedDate!,
                  categoryId: localSelectedCategory!.id!,
                  paymentMethodId: localSelectedPaymentMethod!.id!,
                );

                await _dbHelper.insertTransaction(transaction);
                await _refreshTransactions();
                await _refreshBudgets();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.transactionAdded,
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                    ),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.teal[700] : Colors.teal[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                l10n.add,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? helperText,
    required bool isDarkMode,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
              : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
          ),
          helperStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isDarkMode ? Colors.amber[400] : Colors.deepPurple[700],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDarkMode ? Colors.white : Colors.grey[900],
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required void Function(T?) onChanged,
    required bool isDarkMode,
    required String Function(T) itemBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
              : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButton<T>(
        value: value,
        hint: Text(
          hint,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
          ),
        ),
        isExpanded: true,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemBuilder(item),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDarkMode ? Colors.white : Colors.grey[900],
              ),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          HapticFeedback.mediumImpact();
          onChanged(newValue);
        },
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDarkMode ? Colors.white : Colors.grey[900],
        ),
        dropdownColor: isDarkMode ? const Color(0xFF2E2E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        underline: const SizedBox(),
        icon: Icon(
          Icons.arrow_drop_down,
          color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        ),
      ),
    );
  }

  Widget _buildDatePickerRow({
    required BuildContext context,
    required DateTime? selectedDate,
    required void Function(DateTime?) onDateSelected,
    required bool isDarkMode,
    required String label,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            selectedDate == null
                ? l10n.noDateChosen
                : '$label: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDarkMode ? Colors.white : Colors.grey[900],
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: const TextTheme(
                      bodyMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                    ),
                    colorScheme: ColorScheme.light(
                      primary: isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
                      onPrimary: Colors.white,
                      surface: isDarkMode ? Colors.grey[900]! : Colors.white,
                    ),
                    dialogBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Text(
            l10n.chooseDate,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.amber[400] : Colors.deepPurple[700],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFF3E5F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkMode
                                ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
                                : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: l10n.searchTransactions,
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                                size: 24,
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                _showFilterDialog();
                              },
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                              size: 24,
                            ),
                          ),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isDarkMode ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        final category = _categories.firstWhere(
                          (cat) => cat.id == transaction.categoryId,
                          orElse: () => Category(id: 1, name: 'Unknown'),
                        );
                        final paymentMethod = _paymentMethods.firstWhere(
                          (pm) => pm.id == transaction.paymentMethodId,
                          orElse: () => PaymentMethod(id: 1, name: 'Unknown'),
                        );
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDarkMode
                                    ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
                                    : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              title: Text(
                                transaction.title,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.grey[900],
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    '${l10n.amount}: ₹${transaction.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                                    ),
                                  ),
                                  Text(
                                    '${l10n.category}: ${category.name}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                                    ),
                                  ),
                                  Text(
                                    '${l10n.paymentMethod}: ${paymentMethod.name}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                                    ),
                                  ),
                                  Text(
                                    '${l10n.date}: ${DateFormat('dd MMM yyyy').format(transaction.date)}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _editTransaction(transaction);
                              },
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: isDarkMode ? Colors.red[400] : Colors.red[600],
                                  size: 24,
                                ),
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  await _dbHelper.deleteTransaction(transaction.id!);
                                  await _refreshTransactions();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.transactionDeleted,
                                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                                      ),
                                      backgroundColor: Colors.green[600],
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: _startListening,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDarkMode
                                    ? [const Color(0xFF26A69A), const Color(0xFF80CBC4)]
                                    : [const Color(0xFF2E7D32), const Color(0xFF81C784)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _showAddTransactionDialog();
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDarkMode
                                    ? [const Color(0xFFAB47BC), const Color(0xFFCE93D8)]
                                    : [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showTranscriptDialog)
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(0.4),
            ),
          if (_showTranscriptDialog)
            Center(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode
                          ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
                          : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isListening ? l10n.listening : l10n.processing,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isListening)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            _voiceTranscript.isEmpty ? l10n.startSpeaking : _voiceTranscript,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isDarkMode ? Colors.amber[300] : Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_isListening)
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _speech.stop();
                          setState(() {
                            _isListening = false;
                            _showTranscriptDialog = false;
                            _voiceTranscript = '';
                            _speechRetryCount = 0;
                          });
                        },
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.amber[400] : Colors.deepPurple[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}