import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../utils/category_styles.dart';

class MonthlyDashboard extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime selectedDate;
  final Function(int) onMonthChanged;
  final String filterType;
  final Function(String) onFilterChanged;
  
  // New props for Toggle
  final bool isCalendarView;
  final Function(bool) onViewChanged;

  const MonthlyDashboard({
    super.key, 
    required this.transactions,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.filterType,
    required this.onFilterChanged,
    required this.isCalendarView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Totals
    double totalExpense = 0;
    final Map<String, double> categoryTotals = {};

    for (var t in transactions) {
      if (t.type == 'income') continue; // Skip income
      totalExpense += t.price;
      categoryTotals[t.category ?? 'Uncategorized'] = (categoryTotals[t.category ?? 'Uncategorized'] ?? 0) + t.price;
    }

    // 2. Sort Categories
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Theme Data shortcuts
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // No card margin, just bottom spacing
      child: Column(
        children: [
          // 1. Minimal Month Header (Fused with View Toggle logic conceptually, but for now just clean header)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: colorScheme.onSurface.withOpacity(0.6)),
                  onPressed: () => onMonthChanged(-1),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  DateFormat('MMMM yyyy', 'th').format(selectedDate),
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.6)),
                  onPressed: () => onMonthChanged(1),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // 2. Dashboard Content (Graph)
          SizedBox(
            height: 260, // Fixed height for graph area
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The Donut Chart
                if (transactions.isNotEmpty)
                  TweenAnimationBuilder<double>(
                    key: ValueKey(selectedDate), 
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic, 
                    builder: (context, value, _) {
                      List<PieChartSectionData> sections = [];
                      for (int i = 0; i < sortedCategories.length; i++) {
                        final entry = sortedCategories[i];
                        // Soft Colors
                        final color = CategoryStyles.getColor(entry.key);
                        
                        sections.add(
                          PieChartSectionData(
                            color: color,
                            value: entry.value,
                            title: '', // No title on sections
                            radius: 12, // THIN STROKE
                            showTitle: false,
                          ),
                        );
                      }

                      // Dummy section if empty handled by outer 'if', so here always has data
                      
                      return PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 90, // Large center hole
                          sectionsSpace: 2, 
                          startDegreeOffset: -90,
                          pieTouchData: PieTouchData(enabled: false),
                        ),
                        swapAnimationDuration: Duration.zero,
                      );
                    },
                  ),
                
                // Center Text (Total)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "ยอดรวม",
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "฿${totalExpense.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold, // Bold
                        color: colorScheme.onSurface,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // 3. Segmented Control Toggle (Flat with indicator)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3), // Very light grey
                borderRadius: BorderRadius.circular(100), // Capsule
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSegmentButton(context, "รายการ", !isCalendarView, () => onViewChanged(false)),
                  _buildSegmentButton(context, "ปฏิทิน", isCalendarView, () => onViewChanged(true)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
  

}

