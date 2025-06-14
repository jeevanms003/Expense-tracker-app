import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/generated/l10n.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/period.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/database/database_helper.dart';
import 'package:expense_tracker/providers/theme_provider.dart';

enum GraphType {
  spendingOverTime,
  spendingByCategory,
  spendingByPaymentMethod,
}

class ReportsContent extends StatefulWidget {
  const ReportsContent({super.key});

  @override
  _ReportsContentState createState() => _ReportsContentState();
}

class _ReportsContentState extends State<ReportsContent> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<PaymentMethod> _paymentMethods = [];
  Period _selectedPeriod = Period.daily;
  GraphType _selectedGraph = GraphType.spendingOverTime;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchData();
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

  Future<void> _fetchData() async {
    try {
      final transactions = await _dbHelper.getTransactions();
      final categories = await _dbHelper.getCategories();
      final paymentMethods = await _dbHelper.getPaymentMethods();
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _categories = categories;
          _paymentMethods = paymentMethods;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

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
                                  ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
                                  : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButton<GraphType>(
                                    value: _selectedGraph,
                                    isExpanded: true,
                                    items: GraphType.values.map((graphType) {
                                      return DropdownMenuItem(
                                        value: graphType,
                                        child: Text(
                                          graphType == GraphType.spendingOverTime
                                              ? l10n.spendingOverTime
                                              : graphType == GraphType.spendingByCategory
                                                  ? l10n.spendingByCategoryTitle
                                                  : l10n.spendingByPaymentMethodTitle,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newGraph) {
                                      HapticFeedback.mediumImpact();
                                      if (mounted) {
                                        setState(() {
                                          _selectedGraph = newGraph!;
                                        });
                                      }
                                    },
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                    dropdownColor: isDarkMode ? const Color(0xFF2E2E2E) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButton<Period>(
                                    value: _selectedPeriod,
                                    isExpanded: true,
                                    items: Period.values.map((period) {
                                      return DropdownMenuItem(
                                        value: period,
                                        child: Text(
                                          period == Period.daily
                                              ? l10n.daily
                                              : period == Period.weekly
                                                  ? l10n.weekly
                                                  : period == Period.monthly
                                                      ? l10n.monthly
                                                      : l10n.yearly,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newPeriod) {
                                      HapticFeedback.mediumImpact();
                                      if (mounted) {
                                        setState(() {
                                          _selectedPeriod = newPeriod!;
                                        });
                                      }
                                    },
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                    dropdownColor: isDarkMode ? const Color(0xFF2E2E2E) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    color: isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
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
                                    _fetchData();
                                  },
                                  tooltip: l10n.refresh,
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
                                  ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
                                  : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.hardEdge,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      _selectedGraph == GraphType.spendingOverTime
                                          ? l10n.spendingOverTime
                                          : _selectedGraph == GraphType.spendingByCategory
                                              ? l10n.spendingByCategoryTitle
                                              : l10n.spendingByPaymentMethodTitle,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                      softWrap: true,
                                      maxLines: null,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 280,
                                    child: _transactions.isEmpty ||
                                            _categories.isEmpty ||
                                            _paymentMethods.isEmpty
                                        ? Center(
                                            child: Text(
                                              l10n.noTransactions,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                                              ),
                                            ),
                                          )
                                        : _buildSelectedGraph(),
                                  ),
                                ],
                              ),
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
      ),
    );
  }

  Widget _buildSelectedGraph() {
    switch (_selectedGraph) {
      case GraphType.spendingOverTime:
        return _buildLineChart();
      case GraphType.spendingByCategory:
        return _buildCategoryPieChart();
      case GraphType.spendingByPaymentMethod:
        return _buildPaymentMethodPieChart();
    }
  }

  Widget _buildLineChart() {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final slots = _getTimeSlots(_selectedPeriod);
    final groupedTotals = _groupTransactions(_transactions, _selectedPeriod);
    final spots = slots.asMap().entries.map((entry) {
      int index = entry.key;
      DateTime slot = entry.value;
      double total = groupedTotals[slot] ?? 0;
      return FlSpot(index.toDouble(), total);
    }).toList();

    if (spots.isEmpty || spots.every((spot) => spot.y == 0)) {
      return Center(
        child: Text(
          l10n.noTransactions,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: (isDarkMode ? Colors.teal[400]! : Colors.teal[600]!).withOpacity(0.2),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
                strokeWidth: 1,
                strokeColor: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= slots.length) return const Text('');
                DateTime slot = slots[index];
                String label;
                switch (_selectedPeriod) {
                  case Period.daily:
                    label = DateFormat.d().format(slot);
                    break;
                  case Period.weekly:
                    label = DateFormat.MMMd().format(slot);
                    break;
                  case Period.monthly:
                    label = DateFormat.yMMM().format(slot);
                    break;
                  case Period.yearly:
                    label = DateFormat.y().format(slot);
                    break;
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
              interval: _selectedPeriod == Period.daily ? 5.0 : 1.0,
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${value.toInt()}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            strokeWidth: 0.5,
          ),
        ),
        minX: 0,
        maxX: (slots.length - 1).toDouble(),
        minY: 0,
        maxY: (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 100),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final periodRange = _getPeriodRange(_selectedPeriod);
    return FutureBuilder<Map<int, double>>(
      future: _dbHelper.getSpendingByCategoryForPeriod(
        startDate: periodRange['start']!,
        endDate: periodRange['end']!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              l10n.noTransactions,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
              ),
            ),
          );
        }

        final spending = snapshot.data!;
        final total = spending.values.fold(0.0, (sum, value) => sum + value);
        final sections = spending.entries.map((entry) {
          final category = _categories.firstWhere(
            (cat) => cat.id == entry.key,
            orElse: () => Category(id: entry.key, name: 'Unknown'),
          );
          final percentage = (entry.value / total) * 100;
          return PieChartSectionData(
            value: entry.value,
            title: '${category.name}\n${percentage.toStringAsFixed(1)}%',
            color: _getColorForIndex(spending.keys.toList().indexOf(entry.key), isDarkMode),
            radius: 100,
            titleStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            badgeWidget: Icon(
              Icons.category,
              size: 16,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black26,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            badgePositionPercentageOffset: 1.1,
          );
        }).toList();

        return SizedBox(
          height: 260,
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodPieChart() {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final periodRange = _getPeriodRange(_selectedPeriod);
    return FutureBuilder<Map<int, double>>(
      future: _dbHelper.getSpendingByPaymentMethodForPeriod(
        startDate: periodRange['start']!,
        endDate: periodRange['end']!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              l10n.noTransactions,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
              ),
            ),
          );
        }

        final spending = snapshot.data!;
        final total = spending.values.fold(0.0, (sum, value) => sum + value);
        final sections = spending.entries.map((entry) {
          final paymentMethod = _paymentMethods.firstWhere(
            (pm) => pm.id == entry.key,
            orElse: () => PaymentMethod(id: entry.key, name: 'Unknown'),
          );
          final percentage = (entry.value / total) * 100;
          return PieChartSectionData(
            value: entry.value,
            title: '${paymentMethod.name}\n${percentage.toStringAsFixed(1)}%',
            color: _getColorForIndex(spending.keys.toList().indexOf(entry.key), isDarkMode),
            radius: 100,
            titleStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            badgeWidget: Icon(
              Icons.payment,
              size: 16,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black26,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            badgePositionPercentageOffset: 1.1,
          );
        }).toList();

        return SizedBox(
          height: 260,
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<DateTime> _getTimeSlots(Period period) {
    DateTime now = DateTime.now();
    switch (period) {
      case Period.daily:
        return List.generate(30, (i) {
          DateTime day = now.subtract(Duration(days: i));
          return DateTime(day.year, day.month, day.day);
        }).reversed.toList();
      case Period.weekly:
        List<DateTime> slots = [];
        DateTime current = _getMonday(now);
        for (int i = 0; i < 52; i++) {
          slots.add(current);
          current = current.subtract(const Duration(days: 7));
        }
        return slots.reversed.toList();
      case Period.monthly:
        List<DateTime> slots = [];
        DateTime current = DateTime(now.year, now.month, 1);
        for (int i = 0; i < 12; i++) {
          slots.add(current);
          current = DateTime(current.year, current.month - 1, 1);
        }
        return slots.reversed.toList();
      case Period.yearly:
        List<DateTime> slots = [];
        int year = now.year;
        for (int i = 0; i < 5; i++) {
          slots.add(DateTime(year - i, 1, 1));
        }
        return slots.reversed.toList();
    }
  }

  Map<DateTime, double> _groupTransactions(List<Transaction> transactions, Period period) {
    Map<DateTime, double> totals = {};
    for (var tx in transactions) {
      DateTime key;
      switch (period) {
        case Period.daily:
          key = DateTime(tx.date.year, tx.date.month, tx.date.day);
          break;
        case Period.weekly:
          key = _getMonday(tx.date);
          break;
        case Period.monthly:
          key = _getFirstDayOfMonth(tx.date);
          break;
        case Period.yearly:
          key = _getFirstDayOfYear(tx.date);
          break;
      }
      totals[key] = (totals[key] ?? 0) + tx.amount;
    }
    return totals;
  }

  Map<String, DateTime> _getPeriodRange(Period period) {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = now;
    switch (period) {
      case Period.daily:
        start = now.subtract(const Duration(days: 30));
        break;
      case Period.weekly:
        start = now.subtract(const Duration(days: 365));
        break;
      case Period.monthly:
        start = DateTime(now.year, now.month - 12, 1);
        break;
      case Period.yearly:
        start = DateTime(now.year - 5, 1, 1);
        break;
    }
    return {'start': start, 'end': end};
  }

  DateTime _getMonday(DateTime date) {
    int daysToSubtract = date.weekday - 1;
    if (daysToSubtract < 0) daysToSubtract += 7;
    return date.subtract(Duration(days: daysToSubtract)).copyWith(hour: 0, minute: 0, second: 0);
  }

  DateTime _getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _getFirstDayOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  Color _getColorForIndex(int index, bool isDarkMode) {
    final colors = [
      isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
      isDarkMode ? Colors.purple[400]! : Colors.purple[600]!,
      isDarkMode ? Colors.green[400]! : Colors.green[600]!,
      isDarkMode ? Colors.pink[400]! : Colors.pink[600]!,
      isDarkMode ? Colors.amber[300]! : Colors.amber[600]!,
      isDarkMode ? Colors.blue[400]! : Colors.blue[600]!,
      isDarkMode ? Colors.red[400]! : Colors.red[600]!,
    ];
    return colors[index % colors.length];
  }
}