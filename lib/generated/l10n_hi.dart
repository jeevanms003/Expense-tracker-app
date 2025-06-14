// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'खर्च ट्रैकर';

  @override
  String get home => 'होम';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get budgets => 'बजट';

  @override
  String get reports => 'रिपोर्ट्स';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get title => 'शीर्षक';

  @override
  String get amount => 'राशि (₹)';

  @override
  String get noDateChosen => 'कोई तारीख नहीं चुनी गई';

  @override
  String get chooseDate => 'तारीख चुनें';

  @override
  String get selectCategory => 'श्रेणी चुनें';

  @override
  String get addCategory => 'श्रेणी जोड़ें';

  @override
  String get addTransaction => 'लेनदेन जोड़ें';

  @override
  String get currentBudgets => 'वर्तमान बजट';

  @override
  String get setBudget => 'बजट सेट करें';

  @override
  String get budgetAmount => 'बजट राशि (₹)';

  @override
  String get noMonthChosen => 'कोई महीना नहीं चुना गया';

  @override
  String get chooseMonth => 'महीना चुनें';

  @override
  String get addBudget => 'बजट जोड़ें';

  @override
  String budgetAdded(Object month) {
    return '$month के लिए बजट जोड़ा गया';
  }

  @override
  String get categoryName => 'श्रेणी का नाम';

  @override
  String categoryAdded(Object categoryName) {
    return 'श्रेणी \"$categoryName\" जोड़ा गया';
  }

  @override
  String get fillAllFields => 'कृपया सभी क्षेत्र भरें';

  @override
  String get amountPositive => 'राशि 0 से अधिक होनी चाहिए';

  @override
  String get categoryEmpty => 'श्रेणी का नाम खाली नहीं हो सकता';

  @override
  String get categoryExists => 'श्रेणी पहले से मौजूद है';

  @override
  String get budgetDeleted => 'बजट हटाया गया';

  @override
  String get noTransactions => 'कोई लेनदेन उपलब्ध नहीं';

  @override
  String get refresh => 'रिफ्रेश';

  @override
  String get daily => 'दैनिक';

  @override
  String get weekly => 'साप्ताहिक';

  @override
  String get monthly => 'मासिक';

  @override
  String get yearly => 'वार्षिक';

  @override
  String get currentMonthBudgets => 'वर्तमान महीने के बजट';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'अंग्रेजी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get kannada => 'कन्नड़';

  @override
  String get selectPaymentMethod => 'भुगतान विधि चुनें';

  @override
  String get recurringTransaction => 'आवर्ती लेनदेन';

  @override
  String get selectFrequency => 'आवृत्ति चुनें';

  @override
  String get searchTransactions => 'लेनदेन खोजें';

  @override
  String get filterTransactions => 'लेनदेन फ़िल्टर करें';

  @override
  String get clearFilters => 'फ़िल्टर साफ करें';

  @override
  String get minAmount => 'न्यूनतम राशि (₹)';

  @override
  String get maxAmount => 'अधिकतम राशि (₹)';

  @override
  String get spendingByCategory => 'श्रेणी के अनुसार खर्च';

  @override
  String get spendingByPaymentMethod => 'भुगतान विधि के अनुसार खर्च';

  @override
  String get suggest => 'सुझाव दें';

  @override
  String get enterTitleToSuggest => 'विवरण सुझाने के लिए शीर्षक दर्ज करें';

  @override
  String get suggestBudgets => 'बजट सुझाएँ';

  @override
  String get budgetSuggestions => 'बजट सुझ';

  @override
  String get noBudgetSuggestions => 'कोई बजट सुझाव उपलब्ध नहीं';

  @override
  String get budgetsAdded => 'बजट सफलतापूर्वक जोड़े गए';

  @override
  String get cancel => 'रद्';

  @override
  String get acceptAll => 'सभी स्वी';

  @override
  String get noBudgets => 'कोई बजट सेट नहीं';

  @override
  String get voiceInput => 'आवाज़ इनपुट';

  @override
  String get speechNotAvailable => 'आवाज़ पहचान उपलब्ध नहीं है';

  @override
  String speechError(Object errorMsg) {
    return 'आवाज़ पहचान त्रुटि: $errorMsg';
  }

  @override
  String get noSpeechDetected => 'कोई आवाज़ नहीं मिली';

  @override
  String get confirmTransaction => 'लेनदेन की पुष्टि करें';

  @override
  String get transactionAdded => 'लेनदेन सफलतापूर्वक जोड़ा गया';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get listening => 'सुन रहा हूँ...';

  @override
  String get startSpeaking => 'बोलना शुरू करें';

  @override
  String get stopListening => 'सुनना बंद करें';

  @override
  String get apply => 'लागू करें';

  @override
  String get spendingInsights => 'खर्च अंतर्दृष्टि';

  @override
  String get category => 'श्रेणी';

  @override
  String get paymentMethod => 'भुगतान विधि';

  @override
  String get addTransactionVoice => 'आवाज़ के माध्यम से लेनद';

  @override
  String get suggestDetails => 'विवरण सुझाएँ';

  @override
  String get add => 'जोड़ें';

  @override
  String get processing => 'प्रसंस्करण...';

  @override
  String get transactionDeleted => 'लेनदेन हटाया गया';

  @override
  String get date => 'तारीख';

  @override
  String budgetExists(Object categoryName, Object month) {
    return '$categoryName के लिए $month में बजट पहले से मौज्';
  }

  @override
  String get budgetUpdated => 'बजट सफलतापूर्वक अपडेट किया गया';

  @override
  String get editTransaction => 'लेनदेन संपादित करें';

  @override
  String get transactionUpdated => 'लेनदेन सफलतापूर्वक अपडेट किया गया';

  @override
  String get save => 'हक्षक';

  @override
  String get spendingOverTime => 'समय के साथ खर्च';

  @override
  String get spendingByCategoryTitle => 'श्रेणी के अनुसार खर्च';

  @override
  String get spendingByPaymentMethodTitle => 'भुगतान विधि के अनुसार खर्च';

  @override
  String get failedToAddBudget => 'बजट जोड़ने में विफल';

  @override
  String get failedToUpdateBudget => 'बजट अपडेट करने में विफल';

  @override
  String get failedToDeleteBudget => 'बजट हटाने में विफल';

  @override
  String get month => 'महीना';

  @override
  String get editBudget => 'Edit Budget';

  @override
  String get invalidCategorySelected => 'अमान्य वर्ग चयनित';

  @override
  String get budgetGoal => 'वित्तीय लक्ष्य (वैकल्पिक)';

  @override
  String get darkMode => 'डार्क मोड';
}
