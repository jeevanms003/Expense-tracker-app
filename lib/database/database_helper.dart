import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/payment_method.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static sqflite.Database? _database;

  DatabaseHelper._init();

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<sqflite.Database> _initDB(String fileName) async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = join(dbPath, fileName);
    return await sqflite.openDatabase(
      path,
      version: 8, // Incremented to add goal column
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        print('Foreign keys enabled');
      },
    );
  }

  Future _createDB(sqflite.Database db, int version) async {
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
    ''');
    await db.execute('''
    CREATE TABLE payment_methods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
    ''');
    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      category_id INTEGER NOT NULL,
      payment_method_id INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories(id),
      FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
    )
    ''');
    await db.execute('''
    CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL,
      month TEXT NOT NULL,
      amount REAL NOT NULL,
      goal TEXT, -- Added for user financial goals
      FOREIGN KEY (category_id) REFERENCES categories(id)
    )
    ''');
    await db.execute('''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
    ''');
    await db.execute('''
    CREATE TABLE user_profile (
      id INTEGER PRIMARY KEY,
      city TEXT,
      is_first_launch INTEGER DEFAULT 1
    )
    ''');
    await db.execute('''
    CREATE TABLE feedback (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tip TEXT NOT NULL,
      is_positive INTEGER NOT NULL,
      timestamp TEXT NOT NULL
    )
    ''');

    await db.insert('categories', {'name': 'Food'});
    await db.insert('categories', {'name': 'Entertainment'});
    await db.insert('categories', {'name': 'Travel'});
    await db.insert('categories', {'name': 'Shopping'});
    await db.insert('categories', {'name': 'Bills'});

    await db.insert('payment_methods', {'name': 'Cash'});
    await db.insert('payment_methods', {'name': 'UPI'});
    await db.insert('payment_methods', {'name': 'Credit Card'});
    await db.insert('payment_methods', {'name': 'Debit Card'});
    await db.insert('payment_methods', {'name': 'Bank Transfer'});

    await db.insert('user_profile', {'id': 1, 'city': 'Unknown', 'is_first_launch': 1});
    print('Database created and initialized');
  }

  Future _upgradeDB(sqflite.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
      ''');
      final categoryCount = sqflite.Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM categories')) ??
          0;
      if (categoryCount == 0) {
        await db.insert('categories', {'name': 'Food'});
        await db.insert('categories', {'name': 'Entertainment'});
        await db.insert('categories', {'name': 'Travel'});
        await db.insert('categories', {'name': 'Shopping'});
        await db.insert('categories', {'name': 'Bills'});
      }
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        payment_method_id INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id),
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
      )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
      ''');
      await db.insert('payment_methods', {'name': 'Cash'});
      await db.insert('payment_methods', {'name': 'UPI'});
      await db.insert('payment_methods', {'name': 'Credit Card'});
      await db.insert('payment_methods', {'name': 'Debit Card'});
      await db.insert('payment_methods', {'name': 'Bank Transfer'});
      await db.execute('''
      ALTER TABLE transactions ADD COLUMN payment_method_id INTEGER NOT NULL DEFAULT 1
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('DROP TABLE IF EXISTS recurring_transactions');
    }
    if (oldVersion < 6) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY,
        city TEXT,
        is_first_launch INTEGER DEFAULT 1
      )
      ''');
      await db.insert('user_profile', {'id': 1, 'city': 'Unknown', 'is_first_launch': 1});
    }
    if (oldVersion < 7) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tip TEXT NOT NULL,
        is_positive INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
      ALTER TABLE budgets ADD COLUMN goal TEXT
      ''');
      print('Added goal column to budgets table');
    }
    print('Database upgraded from version $oldVersion to $newVersion');
  }

  Future<void> insertFeedback(String tip, bool isPositive) async {
    try {
      final db = await database;
      await db.insert(
        'feedback',
        {
          'tip': tip,
          'is_positive': isPositive ? 1 : 0,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting feedback: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getFeedbackSummary() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT tip, SUM(is_positive) as positive_count, COUNT(*) - SUM(is_positive) as negative_count
        FROM feedback
        GROUP BY tip
      ''');
      return {
        for (var row in result)
          row['tip'] as String: {
            'positive': row['positive_count'] as int,
            'negative': row['negative_count'] as int,
          }[row['tip'] as String]!
      };
    } catch (e) {
      print('Error getting feedback summary: $e');
      return {};
    }
  }

  Future<void> insertTransaction(Transaction transaction) async {
    try {
      final db = await database;
      await db.insert('transactions', transaction.toMap(),
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
    } catch (e) {
      print('Error inserting transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final db = await database;
      await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactions({
    String? searchQuery,
    List<int>? categoryIds,
    List<int>? paymentMethodIds,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      final db = await database;
      final List<String> whereClauses = [];
      final List<dynamic> whereArgs = [];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereClauses.add('(transactions.title LIKE ? OR categories.name LIKE ?)');
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
      }

      if (categoryIds != null && categoryIds.isNotEmpty) {
        whereClauses.add('transactions.category_id IN (${categoryIds.map((_) => '?').join(',')})');
        whereArgs.addAll(categoryIds);
      }

      if (paymentMethodIds != null && paymentMethodIds.isNotEmpty) {
        whereClauses.add('transactions.payment_method_id IN (${paymentMethodIds.map((_) => '?').join(',')})');
        whereArgs.addAll(paymentMethodIds);
      }

      if (startDate != null) {
        whereClauses.add('transactions.date >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClauses.add('transactions.date <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      if (minAmount != null) {
        whereClauses.add('transactions.amount >= ?');
        whereArgs.add(minAmount);
      }

      if (maxAmount != null) {
        whereClauses.add('transactions.amount <= ?');
        whereArgs.add(maxAmount);
      }

      final query = '''
        SELECT transactions.*
        FROM transactions
        JOIN categories ON transactions.category_id = categories.id
        ${whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : ''}
        ORDER BY transactions.date DESC
      ''';

      final maps = await db.rawQuery(query, whereArgs);
      return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  Future<List<Transaction>> getTransactionsForMonth(String month) async {
    try {
      final db = await database;
      final maps = await db.query(
        'transactions',
        where: "strftime('%Y-%m', date) = ?",
        whereArgs: [month],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
    } catch (e) {
      print('Error getting transactions for month: $e');
      return [];
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final db = await database;
      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final db = await database;
      final maps = await db.query('categories', orderBy: 'name ASC');
      return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final db = await database;
      final maps = await db.query('payment_methods', orderBy: 'name ASC');
      return List.generate(maps.length, (i) => PaymentMethod.fromMap(maps[i]));
    } catch (e) {
      print('Error getting payment methods: $e');
      return [];
    }
  }

  Future<void> insertCategory(String name) async {
    try {
      final db = await database;
      await db.insert(
        'categories',
        {'name': name.trim()},
        conflictAlgorithm: sqflite.ConflictAlgorithm.ignore,
      );
      print('Inserted category: $name');
    } catch (e) {
      print('Error inserting category: $e');
      rethrow;
    }
  }

  Future<List<Budget>> getBudgets() async {
    try {
      final db = await database;
      final maps = await db.query(
        'budgets',
        orderBy: 'month DESC, category_id ASC',
      );
      print('Fetched ${maps.length} budgets');
      return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
    } catch (e) {
      print('Error getting budgets: $e');
      rethrow;
    }
  }

  Future<int> insertBudget(Budget budget) async {
    try {
      final db = await database;
      print('Attempting to insert budget: ${budget.toMap()}');
      final id = await db.insert(
        'budgets',
        budget.toMap(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.fail,
      );
      print('Inserted budget: ID $id, Category ID: ${budget.categoryId}, Month: ${budget.month}, Amount: ${budget.amount}, Goal: ${budget.goal}');
      return id;
    } catch (e) {
      print('Error inserting budget: $e, Budget data: ${budget.toMap()}');
      rethrow;
    }
  }

  Future<int> updateBudget(Budget budget) async {
    try {
      final db = await database;
      final rowsAffected = await db.update(
        'budgets',
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
      );
      print('Updated budget: ID ${budget.id}, Category ID: ${budget.categoryId}, Month: ${budget.month}, Amount: ${budget.amount}, Goal: ${budget.goal}, Rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error updating budget: $e');
      rethrow;
    }
  }

  Future<int> deleteBudget(int id) async {
    try {
      final db = await database;
      final rowsAffected = await db.delete(
        'budgets',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Deleted budget: ID $id, Rows affected: $rowsAffected');
      return id;
    } catch (e) {
      print('Error deleting budget: $e');
      rethrow;
    }
  }

  Future<double> getSpendingForCategoryAndMonth(int categoryId, String month) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        '''
        SELECT SUM(amount) AS total
        FROM transactions
        WHERE category_id = ? AND strftime('%Y-%m', date) = ?
        ''',
        [categoryId, month],
      );
      final total = (result[0]['total'] as num?)?.toDouble() ?? 0.0;
      print('Spending for category $categoryId, month $month: $total');
      return total;
    } catch (e) {
      print('Error getting spending for category $categoryId, month $month: $e');
      rethrow;
    }
  }

  Future<double> getTotalSpendingForMonth(String month) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT SUM(amount) AS total
        FROM transactions
        WHERE strftime('%Y-%m', date) = ?
        ''', [month]);
      return (result[0]['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error getting total spending: $e');
      return 0.0;
    }
  }

  Future<Map<int, double>> getSpendingByCategoryForMonth(String month) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT category_id, SUM(amount) AS total
        FROM transactions
        WHERE strftime('%Y-%m', date) = ?
        GROUP BY category_id
        ''', [month]);
      return Map.fromEntries(result.map((row) =>
          MapEntry(row['category_id'] as int, (row['total'] as num).toDouble())));
    } catch (e) {
      print('Error getting spending by category: $e');
      return {};
    }
  }

  Future<Map<int, double>> getSpendingByPaymentMethodForMonth(String month) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT payment_method_id, SUM(amount) AS total
        FROM transactions
        WHERE strftime('%Y-%m', date) = ?
        GROUP BY payment_method_id
        ''', [month]);
      return Map.fromEntries(result.map((row) =>
          MapEntry(row['payment_method_id'] as int, (row['total'] as num).toDouble())));
    } catch (e) {
      print('Error getting spending by payment method: $e');
      return {};
    }
  }

  Future<Map<int, double>> getSpendingByCategoryForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT category_id, SUM(amount) AS total
        FROM transactions
        WHERE date >= ? AND date <= ?
        GROUP BY category_id
        ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
      return Map.fromEntries(result.map((row) =>
          MapEntry(row['category_id'] as int, (row['total'] as num).toDouble())));
    } catch (e) {
      print('Error getting spending by category ID: $e');
      return {};
    }
  }

  Future<Map<int, double>> getSpendingByPaymentMethodForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT payment_method_id, SUM(amount) AS total
        FROM transactions
        WHERE date >= ? AND date <= ?
        GROUP BY payment_method_id
        ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
      return Map.fromEntries(result.map((row) =>
          MapEntry(row['payment_method_id'] as int, (row['total'] as num).toDouble())));
    } catch (e) {
      print('Error getting spending by payment method for period: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> debugGetAllCategories() async {
    try {
      final db = await database;
      return await db.query('categories');
    } catch (e) {
      print('Error debugging categories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> debugGetAllBudgets() async {
    try {
      final db = await database;
      return await db.query('budgets');
    } catch (e) {
      print('Error debugging budgets: $e');
      return [];
    }
  }

  Future<void> debugDatabase() async {
    try {
      final db = await database;
      final tables = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
      print('Tables in database: $tables');
      final budgetsSchema = await db.rawQuery('PRAGMA table_info(budgets)');
      print('Budgets table schema: $budgetsSchema');
      final categories = await debugGetAllCategories();
      print('All categories: $categories');
      final budgets = await debugGetAllBudgets();
      print('All budgets: $budgets');
    } catch (e) {
      print('Error debugging database: $e');
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<void> setLanguage(String language) async {
    try {
      final db = await database;
      await db.execute(
          'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
      await db.insert(
        'settings',
        {'key': 'language', 'value': language},
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  Future<String> getLanguage() async {
    try {
      final db = await database;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['language'],
      );
      return result.isNotEmpty ? result[0]['value'] as String : 'en';
    } catch (e) {
      print('Error getting language: $e');
      return 'en';
    }
  }

  Future<String?> getUserCity() async {
    try {
      final db = await database;
      final result = await db.query(
        'user_profile',
        where: 'id = ?',
        whereArgs: [1],
      );
      return result.isNotEmpty ? result[0]['city'] as String? : null;
    } catch (e) {
      print('Error getting user city: $e');
      return null;
    }
  }

  Future<void> setUserCity(String city) async {
    try {
      final db = await database;
      await db.insert(
        'user_profile',
        {'id': 1, 'city': city, 'is_first_launch': 1},
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
      print('Set user city: $city');
    } catch (e) {
      print('Error setting user city: $e');
      rethrow;
    }
  }

  Future<bool> isFirstLaunch() async {
    try {
      final db = await database;
      final result = await db.query(
        'user_profile',
        where: 'id = ?',
        whereArgs: [1],
      );
      return result.isEmpty || (result[0]['is_first_launch'] as int? ?? 1) == 1;
    } catch (e) {
      print('Error checking first launch: $e');
      return true;
    }
  }

  Future<void> setFirstLaunch(bool isFirst) async {
    try {
      final db = await database;
      final currentCity = await getUserCity() ?? 'Unknown';
      await db.insert(
        'user_profile',
        {'id': 1, 'city': currentCity, 'is_first_launch': isFirst ? 1 : 0},
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
      print('Set first launch: $isFirst');
    } catch (e) {
      print('Error setting first launch: $e');
      rethrow;
    }
  }
}