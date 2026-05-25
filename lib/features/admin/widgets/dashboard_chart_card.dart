import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/colors.dart';

const _kCategories = ['Fall', 'Agitation', 'Pacing', 'Inactivity', 'Lying Down'];

const _kCategoryColors = {
  'Fall':        AppColors.chartFall,
  'Agitation':   AppColors.chartAgitation,
  'Pacing':      AppColors.chartPacing,
  'Inactivity':  AppColors.chartInactivity,
  'Lying Down':  AppColors.chartLyingDown,
};

class ChartDayData {
  final String name;
  final String date;
  final int alerts;
  final Map<String, int> categories;

  const ChartDayData({
    required this.name,
    required this.date,
    required this.alerts,
    required this.categories,
  });

  factory ChartDayData.fromMap(Map<String, dynamic> map) {
    final dateStr = map['date'] as String? ?? '';
    String name = '';
    if (dateStr.isNotEmpty) {
      final d = DateTime.tryParse('${dateStr}T00:00:00');
      if (d != null) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        name = days[d.weekday - 1];
      }
    }
    return ChartDayData(
      name:   name,
      date:   dateStr,
      alerts: (map['total'] as num?)?.toInt() ?? 0,
      categories: {
        for (final cat in _kCategories)
          cat: (map[cat] as num?)?.toInt() ?? 0,
      },
    );
  }

  factory ChartDayData.empty(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return ChartDayData(
      name:       days[date.weekday % 7],
      date:       '$y-$m-$d',
      alerts:     0,
      categories: {for (final c in _kCategories) c: 0},
    );
  }
}

List<ChartDayData> buildWeekRows(List<dynamic> raw) {
  final now    = DateTime.now();
  final sunday = now.subtract(Duration(days: now.weekday % 7));
  final week   = List.generate(7, (i) => ChartDayData.empty(sunday.add(Duration(days: i))));
  for (final item in raw) {
    final row    = ChartDayData.fromMap(item as Map<String, dynamic>);
    final parsed = DateTime.tryParse('${row.date}T00:00:00');
    if (parsed == null) continue;
    final idx = parsed
        .difference(DateTime(sunday.year, sunday.month, sunday.day))
        .inDays;
    if (idx >= 0 && idx < 7) week[idx] = row;
  }
  return week;
}

class DashboardChartCard extends StatelessWidget {
  final List<dynamic> rawData;
  final bool isLoading;
  final String? error;

  const DashboardChartCard({
    super.key,
    required this.rawData,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days   = buildWeekRows(rawData);

    final weeklyTotal = days.fold<int>(0, (acc, d) => acc + d.alerts);
    final peakDay     = days.reduce((a, b) => a.alerts >= b.alerts ? a : b);

    final cardBg    = isDark ? AppColors.dashBg : Colors.white;
    final borderCol = isDark ? AppColors.dashSurface : const Color(0xFFDEEDF5);

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF00A8E8).withValues(alpha: 0.05),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark, weeklyTotal, peakDay),
          _buildChart(isDark, days),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, int weeklyTotal, ChartDayData peakDay) {
    final labelColor = isDark ? AppColors.dashTextMuted    : const Color(0xFF7A9AAD);
    final titleColor = isDark ? AppColors.dashTextPrimary  : const Color(0xFF00212E);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + chips
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALERT ANALYTICS',
                      style: TextStyle(
                        fontSize:      9,
                        fontWeight:    FontWeight.w800,
                        letterSpacing: 1.5,
                        color:         labelColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '7-Day Overview',
                      style: TextStyle(
                        fontSize:      15,
                        fontWeight:    FontWeight.w900,
                        letterSpacing: -0.4,
                        height:        1.1,
                        color:         titleColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Stat chips
              Row(
                children: [
                  _MiniChip(
                    value:      weeklyTotal.toString(),
                    label:      'TOTAL',
                    valueColor: const Color(0xFF00A8E8),
                    isDark:     isDark,
                  ),
                  if (peakDay.alerts > 0) ...[
                    const SizedBox(width: 6),
                    _MiniChip(
                      value:      peakDay.name,
                      label:      'PEAK',
                      valueColor: isDark ? const Color(0xFFCCEDFA) : const Color(0xFF00435C),
                      isDark:     isDark,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          // Legend — inline single row, no wrapping
          _buildLegend(isDark),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _kCategories.map((cat) {
          final color = _kCategoryColors[cat]!;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width:  6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  cat,
                  style: TextStyle(
                    fontSize:   9,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.dashTextSecondary : const Color(0xFF5A7A8A),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(bool isDark, List<ChartDayData> days) {
    if (isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF00A8E8), strokeWidth: 2.5),
        ),
      );
    }

    if (error != null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            error!,
            style: TextStyle(
              color:      isDark ? AppColors.dashTextMuted : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
              fontSize:   12,
            ),
          ),
        ),
      );
    }

    final maxY     = days.fold<int>(0, (m, d) => d.alerts > m ? d.alerts : m);
    final yMax     = (maxY * 1.25).ceilToDouble().clamp(4.0, double.infinity);
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 14, 10),
        child: BarChart(
          BarChartData(
            maxY: yMax,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (_, _, _, _) => null,
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles:   true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) return const SizedBox();
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color:      isDark ? AppColors.dashTextMuted : const Color(0xFFB0C8D4),
                        fontSize:   9,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles:   true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= days.length) return const SizedBox();
                    final isToday = days[i].date == todayStr;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        days[i].name,
                        style: TextStyle(
                          color: isToday
                              ? const Color(0xFF00A8E8)
                              : (isDark ? AppColors.dashTextMuted : const Color(0xFF94A3B8)),
                          fontSize:   9,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show:             true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color:       isDark
                    ? const Color(0xFF00435C).withValues(alpha: 0.45)
                    : const Color(0xFFDEEDF5),
                strokeWidth: 1,
                dashArray:   [3, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups:  List.generate(days.length, (i) => _buildBarGroup(i, days[i], isDark)),
            groupsSpace: 7,
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int index, ChartDayData day, bool isDark) {
    double runningY = 0;
    final rods = <BarChartRodData>[];

    for (int ci = 0; ci < _kCategories.length; ci++) {
      final cat   = _kCategories[ci];
      final value = day.categories[cat]?.toDouble() ?? 0;
      if (value <= 0) continue;

      final isTop = ci == _kCategories.length - 1 ||
          _kCategories.sublist(ci + 1).every((c) => (day.categories[c] ?? 0) == 0);

      rods.add(BarChartRodData(
        fromY:  runningY,
        toY:    runningY + value,
        color:  _kCategoryColors[cat]!,
        width:  20,
        borderRadius: isTop
            ? const BorderRadius.vertical(top: Radius.circular(4))
            : BorderRadius.zero,
      ));
      runningY += value;
    }

    if (rods.isEmpty) {
      rods.add(BarChartRodData(
        fromY:        0,
        toY:          0.10,
        color:        isDark
            ? const Color(0xFF00435C).withValues(alpha: 0.25)
            : const Color(0xFFDEEDF5),
        width:        20,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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

class _MiniChip extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final bool isDark;

  const _MiniChip({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.dashSurface : const Color(0xFFEEF7FC),
        borderRadius: BorderRadius.circular(9),
        border:       Border.all(
          color: isDark ? AppColors.dashBorder : const Color(0xFFB8DFF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize:       MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize:      16,
              fontWeight:    FontWeight.w900,
              letterSpacing: -0.4,
              color:         valueColor,
              height:        1.0,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize:      7,
              fontWeight:    FontWeight.w800,
              letterSpacing: 0.6,
              color:         isDark ? AppColors.dashTextMuted : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}