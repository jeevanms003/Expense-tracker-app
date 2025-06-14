// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get appTitle => 'ವೆಚ್ಚ ಟ್ರ್ಯಾಕರ್';

  @override
  String get home => 'ಮುಖಪುಟ';

  @override
  String get dashboard => 'ಡಾಶ್‌ಬೋರ್ಡ್';

  @override
  String get budgets => 'ಬಜೆಟ್‌ಗಳು';

  @override
  String get reports => 'ವರದಿಗಳು';

  @override
  String get settings => 'ಸೆಟ್ಟಿಂಗ್ಸ್';

  @override
  String get title => 'ಶೀರ್ಷಿಕೆ';

  @override
  String get amount => 'ಮೊತ್ತ (₹)';

  @override
  String get noDateChosen => 'ದಿನಾಂಕ ಆಯ್ಕೆಯಾಗಿಲ್ಲ';

  @override
  String get chooseDate => 'ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get selectCategory => 'ವರ್ಗ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get addCategory => 'ವರ್ಗ ಸೇರಿಸಿ';

  @override
  String get addTransaction => 'ವಹಿವಾಟು ಸೇರಿಸಿ';

  @override
  String get currentBudgets => 'ಪ್ರಸ್ತುತ ಬಜೆಟ್‌ಗಳು';

  @override
  String get setBudget => 'ಬಜೆಟ್ ಹೊಂದಿಸಿ';

  @override
  String get budgetAmount => 'ಬಜೆಟ್ ಮೊತ್ತ (₹)';

  @override
  String get noMonthChosen => 'ತಿಂಗಳು ಆಯ್ಕೆಯಾಗಿಲ್ಲ';

  @override
  String get chooseMonth => 'ತಿಂಗಳು ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get addBudget => 'ಬಜೆಟ್ ಸೇರಿಸಿ';

  @override
  String budgetAdded(Object month) {
    return '$month ಗೆ ಬಜೆಟ್ ಸೇರಿಸಲಾಗಿದೆ';
  }

  @override
  String get categoryName => 'ವರ್ಗದ ಹೆಸರು';

  @override
  String categoryAdded(Object categoryName) {
    return 'ವರ್ಗ \"$categoryName\" ಸೇರಿಸಲಾಗಿದೆ';
  }

  @override
  String get fillAllFields => 'ದಯವಿಟ್ಟು ಎಲ್ಲಾ ಕ್ಷೇತ್ರಗಳನ್ನು ಭರ್ತಿ ಮಾಡಿ';

  @override
  String get amountPositive => 'ಮೊತ್ತ 0 ಕ್ಕಿಂತ ಹೆಚ್ಚಿರಬೇಕು';

  @override
  String get categoryEmpty => 'ವರ್ಗದ ಹೆಸರು ಖಾಲಿಯಾಗಿರಬಾರದು';

  @override
  String get categoryExists => 'ವರ್ಗ ಈಗಾಗಲೇ ಇದೆ';

  @override
  String get budgetDeleted => 'ಬಜೆಟ್ ಅಳಿಸಲಾಗಿದೆ';

  @override
  String get noTransactions => 'ಯಾವುದೇ ವಹಿವಾಟುಗಳು ಲಭ್ಯವಿಲ್ಲ';

  @override
  String get refresh => 'ರಿಫ್ರೆಶ್';

  @override
  String get daily => 'ದೈನಂದಿನ';

  @override
  String get weekly => 'ಸಾಪ್ತಾಹಿಕ';

  @override
  String get monthly => 'ಮಾಸಿಕ';

  @override
  String get yearly => 'ವಾರ್ಷಿಕ';

  @override
  String get currentMonthBudgets => 'ಪ್ರಸ್ತುತ ತಿಂಗಳ ಬಜೆಟ್‌ಗಳು';

  @override
  String get language => 'ಭಾಷೆ';

  @override
  String get english => 'ಇಂಗ್ಲಿಷ್';

  @override
  String get hindi => 'ಹಿಂದಿ';

  @override
  String get kannada => 'ಕನ್ನಡ';

  @override
  String get selectPaymentMethod => 'ಪಾವತಿ ವಿಧಾನ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get recurringTransaction => 'ಪುನರಾವರ್ತಿತ ವಹಿವಾಟು';

  @override
  String get selectFrequency => 'ಆವರ್ತನೆ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get searchTransactions => 'ವಹಿವಾಟುಗಳನ್ನು ಹುಡುಕಿ';

  @override
  String get filterTransactions => 'ವಹಿವಾಟುಗಳನ್ನು ಫಿಲ್ಟರ್ ಮಾಡಿ';

  @override
  String get clearFilters => 'ಫಿಲ್ಟರ್‌ಗಳನ್ನು ತೆರವುಗೊಳಿಸಿ';

  @override
  String get minAmount => 'ಕನಿಷ್ಠ ಮೊತ್ತ (₹)';

  @override
  String get maxAmount => 'ಗರಿಷ್ಠ ಮೊತ್ತ (₹)';

  @override
  String get spendingByCategory => 'ವರ್ಗದ ಪ್ರಕಾರ ವೆಚ್ಚ';

  @override
  String get spendingByPaymentMethod => 'ಪಾವತಿ ವಿಧಾನದ ಪ್ರಕಾರ ವೆಚ್ಚ';

  @override
  String get suggest => 'ಸೂಚಿಸಿ';

  @override
  String get enterTitleToSuggest => 'ವಿವರಗಳನ್ನು ಸೂಚಿಸಲು ಶೀರ್ಷಿಕೆಯನ್ನು ನಮೂದಿಸಿ';

  @override
  String get suggestBudgets => 'ಬಜೆಟ್‌ಗಳನ್ನು ಸೂಚಿಸಿ';

  @override
  String get budgetSuggestions => 'ಬಜೆಟ್ ಸೂಚನೆಗಳು';

  @override
  String get noBudgetSuggestions => 'ಯಾವುದೇ ಬಜೆಟ್ ಸೂಚನೆಗಳು ಲಭ್ಯವಿಲ್ಲ';

  @override
  String get budgetsAdded => 'ಬಜೆಟ್‌ಗಳನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಸೇರಿಸಲಾಗಿದೆ';

  @override
  String get cancel => 'ರದ್ದುಮಾಡಿ';

  @override
  String get acceptAll => 'ಎಲ್ಲವನ್ನೂ ಸ್ವೀಕರಿಸಿ';

  @override
  String get noBudgets => 'ಯಾವುದೇ ಬಜೆಟ್‌ಗಳನ್ನು ಹೊಂದಿಸಲಾಗಿಲ್ಲ';

  @override
  String get voiceInput => 'ಧ್ವನಿ ಇನ್‌ಪುಟ್';

  @override
  String get speechNotAvailable => 'ಧ್ವನಿ ಗುರುತಿಸುವಿಕೆ ಲಭ್ಯವಿಲ್ಲ';

  @override
  String speechError(Object errorMsg) {
    return 'ಧ್ವನಿ ಗುರುತಿಸುವಿಕೆ ದೋಷ: $errorMsg';
  }

  @override
  String get noSpeechDetected => 'ಯಾವುದೇ ಧ್ವನಿ ಕಂಡುಬಂದಿಲ್ಲ';

  @override
  String get confirmTransaction => 'ವಹಿವಾಟನ್ನು ದೃಢೀಕರಿಸಿ';

  @override
  String get transactionAdded => 'ವಹಿವಾಟು ಯಶಸ್ವಿಯಾಗಿ ಸೇರಿಸಲಾಗಿದೆ';

  @override
  String get confirm => 'ದೃಢೀಕರಿಸಿ';

  @override
  String get listening => 'ಕೇಳುತ್ತಿದೆ...';

  @override
  String get startSpeaking => 'ಮಾತನಾಡಲು ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get stopListening => 'ಕೇಳುವುದನ್ನು ನಿಲ್ಲಿಸಿ';

  @override
  String get apply => 'ಅನ್ವಯಿಸಿ';

  @override
  String get spendingInsights => 'ವೆಚ್ಚದ ಒಳನೋಟ';

  @override
  String get category => 'ವರ್ಗ';

  @override
  String get paymentMethod => 'ಪಾವತಿ ವಿಧಾನ';

  @override
  String get addTransactionVoice => 'ಧ್ವನಿಯ ಮೂಲಕ ವಹಿವಾಟು ಸೇರಿಸಿ';

  @override
  String get suggestDetails => 'ವಿವರಗಳನ್ನು ಸೂಚಿಸಿ';

  @override
  String get add => 'ಸೇರಿಸಿ';

  @override
  String get processing => 'ಸಂಸ್ಕರಣೆ...';

  @override
  String get transactionDeleted => 'ವಹಿವಾಟು ಅಳಿಸಲಾಗಿದೆ';

  @override
  String get date => 'ದಿನಾಂಕ';

  @override
  String budgetExists(Object categoryName, Object month) {
    return '$categoryName ಗೆ $month ರಲ್ಲಿ ಬಜೆಟ್ ಈಗಾಗಲೇ ಇದೆ';
  }

  @override
  String get budgetUpdated => 'ಬಜೆಟ್ ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ';

  @override
  String get editTransaction => 'ವಹಿವಾಟು ಸಂಪಾದಿಸಿ';

  @override
  String get transactionUpdated => 'ವಹಿವಾಟು ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ';

  @override
  String get save => 'ಉಳಿಸಿ';

  @override
  String get spendingOverTime => 'ಕಾಲಾನಂತರದ ವೆಚ್ಚ';

  @override
  String get spendingByCategoryTitle => 'ವರ್ಗದ ಪ್ರಕಾರ ವೆಚ್ಚ';

  @override
  String get spendingByPaymentMethodTitle => 'ಪಾವತಿ ವಿಧಾನದ ಪ್ರಕಾರ ವೆಚ್ಚ';

  @override
  String get failedToAddBudget => 'ಬಜೆಟ್ ಸೇರಿಸಲು ವಿಫಲವಾಗಿದೆ';

  @override
  String get failedToUpdateBudget => 'ಬಜೆಟ್ ನವೀಕರಿಸಲು ವಿಫಲವಾಗಿದೆ';

  @override
  String get failedToDeleteBudget => 'ಬಜೆಟ್ ತೆಗೆದುಹಾಕಲು ವಿಫಲವಾಗಿದೆ';

  @override
  String get month => 'ತಿಂಗಳು';

  @override
  String get editBudget => 'ಬಜೆಟ್ ಸಂಪಾದಿಸಿ';

  @override
  String get invalidCategorySelected => 'ಅಮಾನ್ಯ ವರ್ಗ ಆಯ್ಕೆಯಾಗಿದೆ';

  @override
  String get budgetGoal => 'ಆರ್ಥಿಕ ಗುರಿ (ಐಚ್ಛಿಕ)';

  @override
  String get darkMode => 'ಡಾರ್ಕ್ ಮೋಡ್';
}
