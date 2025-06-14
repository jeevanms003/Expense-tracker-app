// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expense Tracker';

  @override
  String get home => 'Home';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get budgets => 'Budgets';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get title => 'Title';

  @override
  String get amount => 'Amount (₹)';

  @override
  String get noDateChosen => 'No Date Chosen';

  @override
  String get chooseDate => 'Choose Date';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get addCategory => 'Add Category';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get currentBudgets => 'Current Budgets';

  @override
  String get setBudget => 'Set Budget';

  @override
  String get budgetAmount => 'Budget Amount (₹)';

  @override
  String get noMonthChosen => 'No Month Chosen';

  @override
  String get chooseMonth => 'Choose Month';

  @override
  String get addBudget => 'Add Budget';

  @override
  String budgetAdded(Object month) {
    return 'Budget for $month added';
  }

  @override
  String get categoryName => 'Category Name';

  @override
  String categoryAdded(Object categoryName) {
    return 'Category \"$categoryName\" added';
  }

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get amountPositive => 'Amount must be greater than 0';

  @override
  String get categoryEmpty => 'Category name cannot be empty';

  @override
  String get categoryExists => 'Category already exists';

  @override
  String get budgetDeleted => 'Budget deleted';

  @override
  String get noTransactions => 'No transactions available';

  @override
  String get refresh => 'Refresh';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get currentMonthBudgets => 'Current Month Budgets';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get kannada => 'Kannada';

  @override
  String get selectPaymentMethod => 'Select Payment Method';

  @override
  String get recurringTransaction => 'Recurring Transaction';

  @override
  String get selectFrequency => 'Select Frequency';

  @override
  String get searchTransactions => 'Search Transactions';

  @override
  String get filterTransactions => 'Filter Transactions';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get minAmount => 'Minimum Amount (₹)';

  @override
  String get maxAmount => 'Maximum Amount (₹)';

  @override
  String get spendingByCategory => 'Spending by Category';

  @override
  String get spendingByPaymentMethod => 'Spending by Payment Method';

  @override
  String get suggest => 'Suggest';

  @override
  String get enterTitleToSuggest => 'Enter a title to suggest details';

  @override
  String get suggestBudgets => 'Suggest Budgets';

  @override
  String get budgetSuggestions => 'Budget Suggestions';

  @override
  String get noBudgetSuggestions => 'No budget suggestions available';

  @override
  String get budgetsAdded => 'Budgets added successfully';

  @override
  String get cancel => 'Cancel';

  @override
  String get acceptAll => 'Accept All';

  @override
  String get noBudgets => 'No budgets set';

  @override
  String get voiceInput => 'Voice Input';

  @override
  String get speechNotAvailable => 'Speech recognition is not available';

  @override
  String speechError(Object errorMsg) {
    return 'Speech recognition error: $errorMsg';
  }

  @override
  String get noSpeechDetected => 'No speech detected';

  @override
  String get confirmTransaction => 'Confirm Transaction';

  @override
  String get transactionAdded => 'Transaction added successfully';

  @override
  String get confirm => 'Confirm';

  @override
  String get listening => 'Listening...';

  @override
  String get startSpeaking => 'Start speaking';

  @override
  String get stopListening => 'Stop Listening';

  @override
  String get apply => 'Apply';

  @override
  String get spendingInsights => 'Spending Insights';

  @override
  String get category => 'Category';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get addTransactionVoice => 'Add Transaction via Voice';

  @override
  String get suggestDetails => 'Suggest Details';

  @override
  String get add => 'Add';

  @override
  String get processing => 'Processing...';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get date => 'Date';

  @override
  String budgetExists(Object categoryName, Object month) {
    return 'Budget already exists for $categoryName in $month';
  }

  @override
  String get budgetUpdated => 'Budget updated successfully';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get transactionUpdated => 'Transaction updated successfully';

  @override
  String get save => 'Save';

  @override
  String get spendingOverTime => 'Spending Over Time';

  @override
  String get spendingByCategoryTitle => 'Spending by Category';

  @override
  String get spendingByPaymentMethodTitle => 'Spending by Payment Method';

  @override
  String get failedToAddBudget => 'Failed to add budget';

  @override
  String get failedToUpdateBudget => 'Failed to update budget';

  @override
  String get failedToDeleteBudget => 'Failed to delete budget';

  @override
  String get month => 'Month';

  @override
  String get editBudget => 'Edit Budget';

  @override
  String get invalidCategorySelected => 'Invalid category selected';

  @override
  String get budgetGoal => 'Financial Goal (Optional)';

  @override
  String get darkMode => 'Dark Mode';
}
