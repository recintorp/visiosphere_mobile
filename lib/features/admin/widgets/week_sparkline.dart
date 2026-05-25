import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/colors.dart';

// Mirrors _kCategories / _kCategoryColors from dashboard_chart_card.dart.
// Import ChartDayData from dashboard_chart_card.dart at the call site.
const _kSparkCategories = ['Fall', 'Agitation', 'Pacing', 'Inactivity', 'Lying Down'];
const _kSparkColors = {
  'Fall':        AppColors.chartFall,
  'Agitation':   AppColors.chartAgitation,
  'Pacing':      AppColors.chartPacing,
  'Inactivity':  AppColors.chartInactivity,
  'Lying Down':  AppColors.chartLyingDown,
};

/// Minimal 7-bar stacked bar chart — no axes, no labels, no touch.
/// Width/height are set by the parent via SizedBox.
class WeekSparkline extends StatelessWidget {
  /// One entry per day of the week (Sun–Sat), length == 7.
  final List<Map<String, int>> days;
  final bool isDark;

  const WeekSparkline({
    super.key,
    required this.days,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = days.fold<int>(
      0,
      (m, d) {
        final total = _kSparkCategories.fold<int>(0, (s, c) => s + (d[c] ?? 0));
        return total > m ? total : m;
      },
    );
    final yMax = (maxY * 1.3).ceilToDouble().clamp(2.0, double.infinity);

    return BarChart(
      BarChartData(
        maxY:         yMax,
        barTouchData: BarTouchData(enabled: false),
        titlesData:   const FlTitlesData(
          leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData:   const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        groupsSpace: 3,
        barGroups: List.generate(days.length, (i) => _buildGroup(i, days[i], isDark)),
      ),
    );
  }

  BarChartGroupData _buildGroup(int index, Map<String, int> day, bool isDark) {
    double runningY = 0;
    final rods = <BarChartRodData>[];

    for (int ci = 0; ci < _kSparkCategories.length; ci++) {
      final cat   = _kSparkCategories[ci];
      final value = (day[cat] ?? 0).toDouble();
      if (value <= 0) continue;

      final isTop = ci == _kSparkCategories.length - 1 ||
          _kSparkCategories.sublist(ci + 1).every((c) => (day[c] ?? 0) == 0);

      rods.add(BarChartRodData(
        fromY:  runningY,
        toY:    runningY + value,
        color:  _kSparkColors[cat]!,
        width:  6,
        borderRadius: isTop
            ? const BorderRadius.vertical(top: Radius.circular(2))
            : BorderRadius.zero,
      ));
      runningY += value;
    }

    if (rods.isEmpty) {
      rods.add(BarChartRodData(
        fromY:        0,
        toY:          0.08,
        color:        isDark
            ? const Color(0xFF00435C).withValues(alpha: 0.3)
            : const Color(0xFFDEEDF5),
        width:        6,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      ));
    }

    return BarChartGroupData(
      x:               index,
      groupVertically: true,
      barRods:         rods,
      showingTooltipIndicators: [],
    );
  }
}