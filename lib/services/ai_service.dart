import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/payment_method.dart';
import '../models/budget.dart';
import 'package:intl/intl.dart';
import '../widgets/home_content.dart' show StringExtension;

class AIService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late final GenerativeModel _model;

  AIService() {
    // Retrieve the API key from .env
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY not found in .env file');
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  Future<String> generateSpendingInsights() async {
    try {
      final transactions = await _dbHelper.getTransactions();
      final categories = await _dbHelper.getCategories();
      final paymentMethods = await _dbHelper.getPaymentMethods();
      if (transactions.isEmpty) return 'No transactions available to analyze.';

      final summary = _buildSpendingSummary(transactions, categories, paymentMethods);
      final prompt = '''
      You are a financial advisor. Based on the following spending summary, provide 2-3 concise, actionable insights in natural language to help the user manage their finances better. Focus on category spending trends, payment method usage, overspending, or savings opportunities.

      Spending Summary:
      $summary

      Format the response as a single paragraph, max 100 words.
      ''';

      final GenerateContentResponse response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No insights generated. Try again later.';
    } catch (e) {
      print('Error generating insights: $e');
      return 'Failed to generate insights: $e';
    }
  }

  Future<List<Map<String, dynamic>>> suggestBudgets(String month) async {
    try {
      final transactions = await _dbHelper.getTransactions();
      final categories = await _dbHelper.getCategories();
      final List<Map<String, dynamic>> suggestions = [];

      for (var category in categories) {
        final spending = await _dbHelper.getSpendingForCategoryAndMonth(category.id ?? 0, month);
        final prompt = '''
        You are a financial advisor. Based on the following data, recommend a monthly budget amount (in ₹) for the category "${category.name}" for the month $month. The user spent ₹$spending in this category last month. Suggest a budget that is realistic, encourages savings, rounded to the nearest 100. Provide the budget amount and a brief explanation (max 50 words).

        Return the response in JSON format:
        {
          "categoryId": ${category.id ?? 0},
          "amount": number,
          "explanation": "string"
        }
        ''';

        try {
          final GenerateContentResponse response = await _model.generateContent([Content.text(prompt)]);
          final result = response.text ?? '{}';
          final parsed = Map<String, dynamic>.from(jsonDecode(result));
          suggestions.add({
            'categoryId': category.id ?? 0,
            'amount': parsed['amount'] ?? (spending > 0 ? (spending * 1.1 / 100).round() * 100 : 1000.0),
            'explanation': parsed['explanation'] ??
                'Set at ${(spending > 0 ? (spending * 1.1 / 100).round() * 100 : 1000.0)} to cover last month’s ₹$spending plus a 10% buffer for flexibility.',
          });
        } catch (e) {
          final budget = spending > 0 ? spending * 1.1 : 1000.0;
          suggestions.add({
            'categoryId': category.id ?? 0,
            'amount': (budget / 100).round() * 100,
            'explanation': 'Set at ${(budget / 100).round() * 100} to cover last month’s ₹$spending plus a 10% buffer for flexibility.',
          });
        }
      }

      return suggestions;
    } catch (e) {
      print('Error suggesting budgets: $e');
      return [];
    }
  }

  Future<List<String>> generateBudgetTips(String? userGoal) async {
    try {
      final transactions = await _dbHelper.getTransactions();
      final categories = await _dbHelper.getCategories();
      final budgets = await _dbHelper.getBudgets();
      final now = DateTime.now();
      final currentMonth = DateFormat('yyyy-MM').format(now);
      final spendingByCategory = await _dbHelper.getSpendingByCategoryForMonth(currentMonth);

      final summary = _buildSpendingSummary(transactions, categories, []);
      final budgetSummary = budgets.map((b) => 'Category ID: ${b.categoryId}, Month: ${b.month}, Amount: ₹${b.amount}').join('\n');
      final goalText = userGoal != null ? 'User Goal: $userGoal\n' : '';

      final prompt = '''
      You are a financial advisor for an Indian user. Based on the spending summary, budgets, and optional user goal, provide 3-5 actionable budget tips (each max 50 words). Focus on overspending categories, savings opportunities, or aligning with the user’s goal. Be specific, practical, and encouraging. Return tips as a JSON array of strings.

      $goalText
      Spending Summary:
      $summary
      Budgets:
      $budgetSummary
      Current Month Spending by Category:
      ${spendingByCategory.entries.map((e) => 'Category ID: ${e.key}, Spending: ₹${e.value}').join('\n')}

      Example tips:
      ["Reduce dining out to twice a week to save ₹500/month.", "Set a ₹2000 limit for shopping to stay within budget.", "Save 10% of income monthly for your vacation goal."]

      Response format:
      ["tip1", "tip2", ...]
      ''';

      final GenerateContentResponse response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text ?? '[]';
      final parsed = List<String>.from(jsonDecode(result));

      if (parsed.isEmpty || parsed.length < 3) {
        final fallbackTips = [
          'Track daily expenses to avoid overspending on small purchases.',
          'Set a ₹1000 monthly limit for discretionary spending like dining.',
          'Save 20% of your income for an emergency fund.',
          if (spendingByCategory.isNotEmpty)
            'Reduce spending on ${categories.firstWhere((c) => c.id == spendingByCategory.keys.first, orElse: () => Category(id: 0, name: 'Unknown')).name} by 10% to save ₹${(spendingByCategory.values.first * 0.1).round()}/month.',
        ];
        return parsed.isEmpty ? fallbackTips.take(3).toList() : [...parsed, ...fallbackTips].take(5).toList();
      }

      return parsed.take(5).toList();
    } catch (e) {
      print('Error generating budget tips: $e');
      return [
        'Track daily expenses to avoid overspending on small purchases.',
        'Set a ₹1000 monthly limit for discretionary spending like dining.',
        'Save 20% of your income for an emergency fund.',
      ];
    }
  }

  Future<String> handleChatQuery(String userQuery) async {
    try {
      final transactions = await _dbHelper.getTransactions();
      final categories = await _dbHelper.getCategories();
      final paymentMethods = await _dbHelper.getPaymentMethods();
      final summary = _buildSpendingSummary(transactions, categories, paymentMethods);

      final prompt = '''
      You are a financial assistant for an expense tracker app. Based on the following spending summary, answer the user's query: "$userQuery". Provide a concise, accurate response (max 100 words). If the query is about specific spending (e.g., "How much did I spend on Food last month?"), use the summary to calculate the answer. For general financial advice, offer practical tips based on category or payment method trends. If the query is unclear, ask for clarification.

      Spending Summary:
      $summary
      ''';

      final GenerateContentResponse response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Please clarify your query, e.g., "How much did I spend on Food?"';
    } catch (e) {
      print('Error handling chat query: $e');
      return 'Failed to process query: $e';
    }
  }

  Future<String> generateExpenseSummary(String month) async {
    try {
      final totalSpending = await _dbHelper.getTotalSpendingForMonth(month);
      final spendingByCategory = await _dbHelper.getSpendingByCategoryForMonth(month);
      final spendingByPaymentMethod = await _dbHelper.getSpendingByPaymentMethodForMonth(month);
      final categories = await _dbHelper.getCategories();
      final paymentMethods = await _dbHelper.getPaymentMethods();

      final categorySummary = categories
          .map((cat) => 'Category: ${cat.name}, Spending: ₹${spendingByCategory[cat.id ?? 0]?.toStringAsFixed(2) ?? '0.00'}')
          .join('\n');
      final paymentMethodSummary = paymentMethods
          .map((pm) => 'Payment Method: ${pm.name}, Spending: ₹${spendingByPaymentMethod[pm.id ?? 0]?.toStringAsFixed(2) ?? '0.00'}')
          .join('\n');

      final prompt = '''
      You are a financial advisor. Based on the following data for $month, generate a concise expense summary (max 150 words). Include:
      - Total spending
      - Breakdown by top categories and payment methods
      - One actionable insight for savings or budgeting based on category or payment method trends

      Data:
      Total Spending: ₹${totalSpending.toStringAsFixed(2)}
      Categories:
      $categorySummary
      Payment Methods:
      $paymentMethodSummary

      Format as a single paragraph.
      ''';

      final GenerateContentResponse response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No summary generated. Try again later.';
    } catch (e) {
      print('Error generating expense summary: $e');
      return 'Failed to generate expense summary: $e';
    }
  }

  Future<Map<String, dynamic>> suggestTransactionDetails(String title) async {
    try {
      final categories = await _dbHelper.getCategories();
      final paymentMethods = await _dbHelper.getPaymentMethods();
      final transactions = await _dbHelper.getTransactions();

      final transactionHistory = transactions
          .map((t) {
            final cat = categories.firstWhere(
              (c) => c.id == t.categoryId,
              orElse: () => Category(id: 0, name: 'Unknown'),
            );
            final pm = paymentMethods.firstWhere(
              (p) => p.id == t.paymentMethodId,
              orElse: () => PaymentMethod(id: 0, name: 'Unknown'),
            );
            return 'Title: ${t.title}, Category: ${cat.name}, Payment Method: ${pm.name}';
          })
          .join('\n');

      final prompt = '''
      You are a financial assistant. Based on the transaction title "$title" and the following transaction history, suggest the most likely category ID and payment method ID. Return the response in JSON format. If unsure, default to category ID 1 (Food) and payment method ID 1 (Cash).

      Categories: ${categories.map((c) => 'ID: ${c.id ?? 0}, Name: ${c.name}').join('; ')}
      Payment Methods: ${paymentMethods.map((p) => 'ID: ${p.id ?? 0}, Name: ${p.name}').join('; ')}
      Transaction History:
      $transactionHistory

      Response format:
      {
        "categoryId": number,
        "paymentMethodId": number
      }
      ''';

      try {
        final GenerateContentResponse response = await _model.generateContent([Content.text(prompt)]);
        final result = response.text?.trim() ?? '{}';
        final parsed = Map<String, dynamic>.from(jsonDecode(result));
        return {
          'categoryId': parsed['categoryId'] ?? 1,
          'paymentMethodId': parsed['paymentMethodId'] ?? 1,
        };
      } catch (e) {
        int categoryId = 1;
        int paymentMethodId = 1;

        final lowerTitle = title.toLowerCase().trim();
        if (lowerTitle.contains('lunch') || lowerTitle.contains('dinner') || lowerTitle.contains('cafe')) {
          categoryId = categories.firstWhere((c) => c.name == 'Food', orElse: () => categories[0]).id ?? 1;
          paymentMethodId = paymentMethods.firstWhere((p) => p.name == 'UPI', orElse: () => paymentMethods[0]).id ?? 1;
        } else if (lowerTitle.contains('movie') || lowerTitle.contains('concert')) {
          categoryId = categories.firstWhere((c) => c.name == 'Entertainment', orElse: () => categories[0]).id ?? 1;
          paymentMethodId = paymentMethods.firstWhere((p) => p.name == 'Credit Card', orElse: () => paymentMethods[0]).id ?? 1;
        } else if (lowerTitle.contains('bill')) {
          categoryId = categories.firstWhere((c) => c.name == 'Bills', orElse: () => categories[0]).id ?? 1;
          paymentMethodId = paymentMethods.firstWhere((p) => p.name == 'Bank Transfer', orElse: () => paymentMethods[0]).id ?? 1;
        }

        return {
          'categoryId': categoryId,
          'paymentMethodId': paymentMethodId,
        };
      }
    } catch (e) {
      print('Error suggesting transaction details: $e');
      return {
        'categoryId': 1,
        'paymentMethodId': 1,
      };
    }
  }

  Future<Map<String, dynamic>> parseVoiceTransaction(String transcript) async {
    try {
      final categories = await _dbHelper.getCategories();
      final paymentMethods = await _dbHelper.getPaymentMethods();
      final transactions = await _dbHelper.getTransactions();

      final transactionHistory = transactions
          .map((t) {
            final cat = categories.firstWhere(
              (c) => c.id == t.categoryId,
              orElse: () => Category(id: 0, name: 'Unknown'),
            );
            final pm = paymentMethods.firstWhere(
              (p) => p.id == t.paymentMethodId,
              orElse: () => PaymentMethod(id: 0, name: 'Unknown'),
            );
            return 'Title: ${t.title}, Category: ${cat.name}, Payment Method: ${pm.name}, Amount: ₹${t.amount}';
          })
          .join('\n');

      final prompt = '''
      You are a financial assistant for an expense tracker app designed for Indian users. Parse the following voice transcript in Indian English: "$transcript". Extract the transaction details: title, amount (in ₹), category ID, payment method ID, and date. Handle informal phrasing (e.g., "rs," "rupaye," "Paytm"), Indian merchant names (e.g., "Pizza Hut," "Zomato"), and number formats (e.g., "500," "five hundred", "one lakh"). Use the provided categories, payment methods, and transaction history to make informed decisions. If the amount is missing, default to 0. If the title is unclear, derive a description from the transcript. If unsure about category or payment method, use a scoring system based on transaction history frequency or default to category ID 1 (Food) and payment method ID 1 (Cash). The date should be the current date unless specified.

      Categories: ${categories.map((c) => 'ID: ${c.id ?? 0}, Name: ${c.name}').join('; ')}
      Payment Methods: ${paymentMethods.map((p) => 'ID: ${p.id ?? 0}, Name: ${p.name}').join('; ')}
      Transaction History:
      $transactionHistory

      Return the response in JSON format:
      {
        "title": "string",
        "amount": number,
        "categoryId": number,
        "paymentMethodId": number,
        "date": "string",
        "confidence": {
          "title": number,
          "amount": number,
          "categoryId": number,
          "paymentMethodId": number
        }
      }
      ''';

      try {
        final GenerateContentResponse response = await _model.generateContent([Content.text(prompt)]);
        final result = response.text?.trim() ?? '{}';
        final parsed = Map<String, dynamic>.from(jsonDecode(result));
        return {
          'title': parsed['title'] ?? 'Unnamed Transaction',
          'amount': (parsed['amount'] is int ? parsed['amount'].toDouble() : parsed['amount']) ?? 0.0,
          'categoryId': parsed['categoryId'] ?? 1,
          'paymentMethodId': parsed['paymentMethodId'] ?? 1,
          'date': parsed['date'] ?? DateTime.now().toIso8601String(),
          'confidence': Map<String, double>.from(parsed['confidence'] ?? {
            'title': 0.5,
            'amount': 0.5,
            'categoryId': 0.5,
            'paymentMethodId': 0.5,
          }),
        };
      } catch (e) {
        final lowerTranscript = transcript.toLowerCase().trim();
        String title = 'Unnamed Transaction';
        double amount = 0.0;
        int categoryId = 1;
        int paymentMethodId = 1;
        String date = DateTime.now().toIso8601String();
        Map<String, double> confidence = {
          'title': 0.5,
          'amount': 0.5,
          'categoryId': 0.5,
          'paymentMethodId': 0.5,
        };

        // Enhanced amount parsing
        final parsedAmount = _parseSpokenNumber(lowerTranscript);
        if (parsedAmount != null) {
          amount = parsedAmount;
          confidence['amount'] = 0.95;
        }

        final paymentKeywords = {
          'upi': ['upi', 'paytm', 'gpay', 'google pay', 'phonepe', 'phone pe'],
          'cash': ['cash', 'money'],
          'credit card': ['card', 'credit card', 'debit card', 'visa', 'mastercard'],
          'bank transfer': ['bank', 'transfer', 'net banking'],
        };
        for (var pm in paymentMethods) {
          final keywords = paymentKeywords[pm.name.toLowerCase()] ?? [pm.name.toLowerCase()];
          if (keywords.any((keyword) => lowerTranscript.contains(keyword))) {
            paymentMethodId = pm.id ?? 1;
            confidence['paymentMethodId'] = 0.9;
            break;
          }
        }

        final categoryKeywords = {
          'Food': ['pizza hut', 'zomato', 'swiggy', 'dominos', 'cafe', 'restaurant', 'lunch', 'dinner', 'food'],
          'Entertainment': ['movie', 'cinema', 'concert', 'netflix', 'prime'],
          'Bills': ['bill', 'electricity', 'water', 'internet'],
          'Transport': ['uber', 'ola', 'taxi', 'bus', 'train'],
          'Shopping': ['amazon', 'flipkart', 'myntra', 'shop'],
        };
        String? matchedMerchant;
        for (var entry in categoryKeywords.entries) {
          for (var keyword in entry.value) {
            if (lowerTranscript.contains(keyword)) {
              categoryId = categories.firstWhere((c) => c.name == entry.key, orElse: () => categories[0]).id ?? 1;
              confidence['categoryId'] = 0.9;
              if (entry.value.contains(keyword) && keyword.length > 3) {
                matchedMerchant = keyword;
              }
              break;
            }
          }
          if (confidence['categoryId']! > 0.5) break;
        }

        if (matchedMerchant != null) {
          title = matchedMerchant.split(' ').map((w) => StringExtension(w).capitalize()).join(' ');
          confidence['title'] = 0.95;
        } else {
          final words = lowerTranscript
              .split(' ')
              .where((w) => !w.contains(RegExp(r'rs|rupees?|rupaye|₹|\d+|upi|cash|card|paytm|gpay|phonepe|lakh|crore|thousand|hundred')))
              .toList();
          title = words.isNotEmpty
              ? words.take(3).map((w) => StringExtension(w).capitalize()).join(' ')
              : 'Expense';
          confidence['title'] = words.isNotEmpty ? 0.8 : 0.6;
        }

        final categoryCounts = <int, int>{};
        final paymentCounts = <int, int>{};
        for (var t in transactions) {
          categoryCounts[t.categoryId] = (categoryCounts[t.categoryId] ?? 0) + 1;
          paymentCounts[t.paymentMethodId] = (paymentCounts[t.paymentMethodId] ?? 0) + 1;
        }
        if (confidence['categoryId']! < 0.7 && categoryCounts.isNotEmpty) {
          categoryId = categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          confidence['categoryId'] = 0.7;
        }
        if (confidence['paymentMethodId']! < 0.7 && paymentCounts.isNotEmpty) {
          paymentMethodId = paymentCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          confidence['paymentMethodId'] = 0.7;
        }

        return {
          'title': title,
          'amount': amount,
          'categoryId': categoryId,
          'paymentMethodId': paymentMethodId,
          'date': date,
          'confidence': confidence,
        };
      }
    } catch (e) {
      print('Error parsing voice transaction: $e');
      return {
        'title': 'Unnamed Transaction',
        'amount': 0.0,
        'categoryId': 1,
        'paymentMethodId': 1,
        'date': DateTime.now().toIso8601String(),
        'confidence': {
          'title': 0.1,
          'amount': 0.0,
          'categoryId': 0.1,
          'paymentMethodId': 0.1,
        },
      };
    }
  }

  String _buildSpendingSummary(List<Transaction> transactions, List<Category> categories,
      List<PaymentMethod> paymentMethods) {
    final now = DateTime.now();
    final lastMonth = DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1));
    final thisMonth = DateFormat('yyyy-MM').format(now);

    final summary = StringBuffer();
    for (var category in categories) {
      for (var pm in paymentMethods) {
        final lastMonthSpending = transactions
            .where((t) =>
                t.categoryId == (category.id ?? 0) &&
                t.paymentMethodId == (pm.id ?? 0) &&
                DateFormat('yyyy-MM').format(t.date) == lastMonth)
            .fold<double>(0, (sum, t) => sum + t.amount);
        final thisMonthSpending = transactions
            .where((t) =>
                t.categoryId == (category.id ?? 0) &&
                t.paymentMethodId == (pm.id ?? 0) &&
                DateFormat('yyyy-MM').format(t.date) == thisMonth)
            .fold<double>(0, (sum, t) => sum + t.amount);

        summary.writeln(
            'Category: ${category.name}, Payment Method: ${pm.name}, Last Month ($lastMonth): ₹${lastMonthSpending.toStringAsFixed(2)}, This Month ($thisMonth): ₹${thisMonthSpending.toStringAsFixed(2)}');
      }
    }
    return summary.toString();
  }

  // Helper function to parse spoken numbers
  double? _parseSpokenNumber(String transcript) {
    // Step 1: Normalize currency terms
    transcript = transcript
        .replaceAll(RegExp(r'\b(rs|rupees?|rupaye|₹)\b', caseSensitive: false), '')
        .trim();

    // Step 2: Handle numeric formats (e.g., "500", "500.50", "1,00,000")
    final numericMatch = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+\.\d+|\d+)').firstMatch(transcript);
    if (numericMatch != null) {
      String numStr = numericMatch.group(0)!.replaceAll(',', '');
      return double.tryParse(numStr);
    }

    // Step 3: Handle written numbers and Indian terms (e.g., "five hundred", "one lakh")
    final wordToNumber = {
      'zero': 0,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'thirteen': 13,
      'fourteen': 14,
      'fifteen': 15,
      'sixteen': 16,
      'seventeen': 17,
      'eighteen': 18,
      'nineteen': 19,
      'twenty': 20,
      'thirty': 30,
      'forty': 40,
      'fifty': 50,
      'sixty': 60,
      'seventy': 70,
      'eighty': 80,
      'ninety': 90,
      'hundred': 100,
      'thousand': 1000,
      'lakh': 100000,
      'crore': 10000000,
    };

    final words = transcript.split(RegExp(r'\s+'));
    double total = 0;
    double current = 0;
    bool hasDecimal = false;
    double decimalValue = 0;
    int decimalPlace = 1;

    for (var word in words) {
      if (word == 'point' || word == 'decimal') {
        hasDecimal = true;
        continue;
      }

      if (hasDecimal) {
        final num = wordToNumber[word.toLowerCase()];
        if (num != null && num < 10) {
          decimalValue += num.toDouble() / (decimalPlace * 10);
          decimalPlace *= 10;
        }
        continue;
      }

      final num = wordToNumber[word.toLowerCase()];
      if (num == null) continue;

      if (num >= 100) {
        current = (current == 0 ? 1 : current) * num.toDouble();
        if (num >= 1000) {
          total += current;
          current = 0;
        }
      } else {
        current += num.toDouble();
      }
    }

    total += current;
    if (hasDecimal) total += decimalValue;

    return total > 0 ? total : null;
  }
}