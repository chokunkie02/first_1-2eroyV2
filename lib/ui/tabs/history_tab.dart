import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../utils/category_styles.dart';
import '../widgets/animated_donut_chart.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/premium_empty_state.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  // Calendar State
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now(); // Default filter

  late final Box<Transaction> box;

  @override
  void initState() {
    super.initState();
    box = DatabaseService().transactionBox;
  }

  // 1. Logic to get filtered transactions
  List<Transaction> _getTransactionsForDay(DateTime day) {
    return box.values.where((tx) {
      return isSameDay(tx.date, day);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }
  
  // Logic for Monthly Totals (Context for Charts)
  List<Transaction> _getTransactionsForMonth(DateTime month) {
     return box.values
        .where((ts) => ts.date.year == month.year && ts.date.month == month.month)
        .toList();
  }
  
  double _calculateMonthTotal(List<Transaction> transactions) {
    return transactions
      .where((tx) => tx.type == 'expense')
      .fold(0.0, (sum, tx) => sum + tx.price);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box<Transaction> box, _) {
            // Data Prep
            final monthlyTransactions = _getTransactionsForMonth(_focusedDay);
            final monthlyTotal = _calculateMonthTotal(monthlyTransactions);
            
            return Column(
              children: [
                // ==========================================
                // 1. Header Section: Month Title & Chart
                // ==========================================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous Month
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                              });
                            },
                            icon: Icon(Icons.chevron_left, color: colorScheme.onSurfaceVariant),
                            visualDensity: VisualDensity.compact,
                          ),
                          
                          // Month Title
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "ภาพรวม", 
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant, 
                                  fontSize: 12,
                                  fontFamily: 'Kanit'
                                ),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(_focusedDay),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Kanit',
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),

                          // Next Month + Toggle Stacked/Row
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                                  });
                                },
                                icon: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 4),
                              // Toggle Button
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _calendarFormat = _calendarFormat == CalendarFormat.week
                                        ? CalendarFormat.month
                                        : CalendarFormat.week;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _calendarFormat == CalendarFormat.week 
                                        ? Icons.calendar_view_month_rounded 
                                        : Icons.calendar_view_week_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Animated Donut Chart
                      AnimatedDonutChart(
                        transactions: monthlyTransactions,
                        total: monthlyTotal,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================================
                // 2. Expandable Calendar Strip
                // ==========================================
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Calendar Widget
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TableCalendar(
                          firstDay: DateTime(2020),
                          lastDay: DateTime.now().add(const Duration(days: 365)),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          
                          // Style & Formatting
                          headerVisible: false,
                          daysOfWeekHeight: 24,
                          rowHeight: 60, // Taller for icons
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            defaultTextStyle: TextStyle(fontFamily: 'Kanit', color: colorScheme.onSurface),
                            weekendTextStyle: TextStyle(fontFamily: 'Kanit', color: colorScheme.error.withOpacity(0.7)),
                          ),
                          
                          // Custom Builders
                          calendarBuilders: CalendarBuilders(
                            // Marker Builder (Top 3 Icons)
                            markerBuilder: (context, date, events) {
                              final txs = box.values.where((t) => isSameDay(t.date, date) && t.type == 'expense').toList();
                              if (txs.isEmpty) return null;
                              
                              // Sort by price desc
                              txs.sort((a, b) => b.price.compareTo(a.price));
                              final top3 = txs.take(3).toList();

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: top3.map((tx) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    child: Icon(
                                      CategoryStyles.getIcon(tx.category ?? 'Other'),
                                      size: 6, // Minimal dot size 
                                      color: CategoryStyles.getColor(tx.category ?? 'Other'),
                                    ),
                                  );
                                }).toList(),
                              );
                            },

                            selectedBuilder: (context, date, events) {
                              return Center(
                                child: Container(
                                  width: 40, height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(14), // Squircle
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${date.day}',
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Kanit'
                                    ),
                                  ),
                                ),
                              );
                            },
                            todayBuilder: (context, date, events) {
                              return Center(
                                child: Container(
                                  width: 40, height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: colorScheme.primary, 
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Kanit'
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Interaction
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay; 
                              if (_calendarFormat == CalendarFormat.month) {
                                _calendarFormat = CalendarFormat.week;
                              }
                            });
                          },
                          onFormatChanged: (format) {
                             if (_calendarFormat != format) {
                               setState(() => _calendarFormat = format);
                             }
                          },
                          onPageChanged: (focusedDay) {
                            // Sync focus when swiping
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          },
                        ),
                      ),
                      
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 32,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // 3. Transaction List (Flexible)
                // ==========================================
                Expanded(
                  child: Container(
                    color: theme.cardTheme.color, 
                    child: Builder( // Filter Logic inside main builder
                      builder: (context) {
                        final dailyTransactions = _selectedDay != null 
                            ? box.values.where((tx) => isSameDay(tx.date, _selectedDay!)).toList()
                            : <Transaction>[];
                        
                        dailyTransactions.sort((a, b) => b.date.compareTo(a.date));

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: dailyTransactions.isEmpty
                              ? const PremiumEmptyState(
                                  key: ValueKey('empty'),
                                  message: "ไม่มีรายการ",
                                  subMessage: "เลือกวันที่อื่น หรือกด + เพื่อเพิ่ม",
                                )
                              : ListView.separated(
                                  key: ValueKey(_selectedDay),
                                  padding: const EdgeInsets.only(bottom: 80, top: 0),
                                  itemCount: dailyTransactions.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1, 
                                    indent: 84, 
                                    endIndent: 24, 
                                    color: colorScheme.outlineVariant.withOpacity(0.4)
                                  ),
                                  itemBuilder: (context, index) {
                                    final tx = dailyTransactions[index];
                                    
                                    const int baseDuration = 400;
                                    const int delayStep = 50;
                                    final int totalDuration = baseDuration + (index * delayStep);
                                    final double startInterval = (index * delayStep) / totalDuration;
                                    
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0.0, end: 1.0),
                                      duration: Duration(milliseconds: totalDuration),
                                      curve: Interval(
                                        startInterval, 
                                        1.0, 
                                        curve: Curves.easeOutCubic
                                      ),
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: Opacity(
                                            opacity: value.clamp(0.0, 1.0),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: TransactionListItem(
                                        transaction: tx,
                                        onTap: () {},
                                        showDivider: false,
                                      ),
                                    );
                                  },
                                ),
                        );
                      }
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

  }
}
