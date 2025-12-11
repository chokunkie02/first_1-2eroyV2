import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../utils/category_styles.dart';

class CalendarHistoryView extends StatefulWidget {
  final List<Transaction> transactions;
  final DateTime focusedDay;

  const CalendarHistoryView({
    super.key, 
    required this.transactions,
    required this.focusedDay,
  });

  @override
  State<CalendarHistoryView> createState() => _CalendarHistoryViewState();
}

class _CalendarHistoryViewState extends State<CalendarHistoryView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  Map<DateTime, List<Transaction>> _groupedTransactions = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay;
    _groupTransactions();
  }

  @override
  void didUpdateWidget(covariant CalendarHistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedDay != widget.focusedDay) {
      setState(() {
        _focusedDay = widget.focusedDay;
      });
    }
    _groupTransactions();
  }

  void _groupTransactions() {
    _groupedTransactions = {};
    for (var tx in widget.transactions) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (_groupedTransactions[date] == null) {
        _groupedTransactions[date] = [];
      }
      _groupedTransactions[date]!.add(tx);
    }
  }

  List<Transaction> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _groupedTransactions[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack, // Pop effect
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value), // Pop from 80% size
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TableCalendar<Transaction>(
            firstDay: DateTime(2020),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              // Optional: Show details for selected day
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: EdgeInsets.all(2),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronVisible: false,
              rightChevronVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();
                
                // Calculate Total
                double total = events.fold(0, (sum, tx) => sum + tx.price);
                
                // Get Top 3 Categories
                Map<String, double> catTotals = {};
                for (var tx in events) {
                  catTotals[tx.category ?? 'Uncategorized'] = (catTotals[tx.category ?? 'Uncategorized'] ?? 0) + tx.price;
                }
                var sortedCats = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                var topCats = sortedCats.take(3).map((e) => e.key).toList();

                return Positioned(
                  bottom: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: topCats.map((cat) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: Icon(
                            CategoryStyles.getIcon(cat),
                            size: 10,
                            color: CategoryStyles.getColor(cat),
                          ),
                        )).toList(),
                      ),
                      // Total Amount
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          NumberFormat.compact().format(total),
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
