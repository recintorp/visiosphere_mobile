import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/dio_client.dart';
import 'week_sparkline.dart';

class _WeekSummary {
  final String startISO;
  final String label;
  final int total;
  final List<Map<String, int>> days;

  const _WeekSummary({
    required this.startISO,
    required this.label,
    required this.total,
    required this.days,
  });
}

DateTime _sundayOfWeek(DateTime d) {
  final x = DateTime(d.year, d.month, d.day);
  return x.subtract(Duration(days: x.weekday % 7));
}

String _iso(DateTime d) {
  final y = d.year;
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _weekLabel(DateTime sunday) {
  final end = sunday.add(const Duration(days: 6));
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[sunday.month]} ${sunday.day} – ${months[end.month]} ${end.day}';
}

String _severityLabel(int total) {
  if (total == 0)  return 'Quiet';
  if (total < 10)  return 'Normal';
  if (total < 20)  return 'Elevated';
  return 'High';
}

Color _severityColor(int total, bool isDark) {
  if (total == 0)  return isDark ? const Color(0xFF4CC2EE) : const Color(0xFF0075A2);
  if (total < 10)  return isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
  if (total < 20)  return isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
  return isDark ? const Color(0xFFFB7185) : const Color(0xFFBE123C);
}

Color _severityBg(int total, bool isDark) {
  if (total == 0) {
    return isDark
        ? const Color(0xFF00A8E8).withValues(alpha: 0.15)
        : const Color(0xFFEEF7FC);
  }
  if (total < 10) {
    return isDark
        ? const Color(0xFF15803D).withValues(alpha: 0.18)
        : const Color(0xFFDCFCE7);
  }
  if (total < 20) {
    return isDark
        ? const Color(0xFFB45309).withValues(alpha: 0.18)
        : const Color(0xFFFEF3C7);
  }
  return isDark
      ? const Color(0xFFBE123C).withValues(alpha: 0.18)
      : const Color(0xFFFFF1F2);
}

Future<_WeekSummary> _fetchWeek(DateTime sunday) async {
  final tz  = DateTime.now().timeZoneName;
  final iso = _iso(sunday);
  final res = await DioClient.instance.get(
    '/incidents/stats/weekly',
    queryParameters: {'weekStart': iso, 'tz': tz},
  );

  final raw        = (res.data as List<dynamic>?) ?? [];
  final categories = ['Fall', 'Agitation', 'Pacing', 'Inactivity', 'Lying Down'];

  final byDate = <String, Map<String, int>>{};
  for (final item in raw) {
    final map  = item as Map<String, dynamic>;
    final date = map['date'] as String? ?? '';
    byDate[date] = {
      for (final c in categories) c: (map[c] as num?)?.toInt() ?? 0,
    };
  }

  final days = List.generate(7, (i) {
    final d   = sunday.add(Duration(days: i));
    final key = _iso(d);
    return byDate[key] ?? {for (final c in categories) c: 0};
  });

  final total = days.fold<int>(
    0,
    (acc, d) => acc + categories.fold<int>(0, (s, c) => s + (d[c] ?? 0)),
  );

  return _WeekSummary(
    startISO: iso,
    label:    _weekLabel(sunday),
    total:    total,
    days:     days,
  );
}

class RecentWeeksStrip extends StatefulWidget {
  const RecentWeeksStrip({super.key});

  @override
  State<RecentWeeksStrip> createState() => _RecentWeeksStripState();
}

class _RecentWeeksStripState extends State<RecentWeeksStrip> {
  List<_WeekSummary>? _weeks;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final now     = DateTime.now();
      final thisSun = _sundayOfWeek(now);

      final results = await Future.wait(
        List.generate(5, (i) => _fetchWeek(
          thisSun.subtract(Duration(days: (i + 1) * 7)),
        )),
      );

      if (mounted) setState(() { _weeks = results; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _weeks = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final cardBg     = isDark ? AppColors.dashBg      : Colors.white;
    final borderCol  = isDark ? AppColors.dashSurface  : const Color(0xFFDEEDF5);
    final labelColor = isDark ? AppColors.dashTextMuted : const Color(0xFF7A9AAD);

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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'RECENT WEEKS',
                        style: TextStyle(
                          fontSize:      9,
                          fontWeight:    FontWeight.w800,
                          letterSpacing: 1.4,
                          color:         labelColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3, height: 3,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.dashSurface : const Color(0xFFB8DFF0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last 5 weeks',
                        style: TextStyle(
                          fontSize:   9,
                          fontWeight: FontWeight.w600,
                          color:      labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap:    () => context.push('/admin/alert-history'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 2, 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize:      10,
                            fontWeight:    FontWeight.w800,
                            color:         Color(0xFF00A8E8),
                            letterSpacing: 0.1,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size:  9,
                          color: Color(0xFF00A8E8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: isDark ? AppColors.dashSurface : const Color(0xFFDEEDF5), height: 1),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? AppColors.dashTextMuted : const Color(0xFFB8DFF0),
                  ),
                ),
              ),
            )
          else if (_weeks == null || _weeks!.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Text(
                'No historical data available',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: labelColor),
              ),
            )
          else
            ..._weeks!.asMap().entries.map((e) => _WeekRow(
              summary: e.value,
              isDark:  isDark,
              isLast:  e.key == _weeks!.length - 1,
              onTap:   () => context.push(
                '/admin/alert-history',
                extra: e.value.startISO,
              ),
            )),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final _WeekSummary summary;
  final bool isDark;
  final bool isLast;
  final VoidCallback onTap;

  const _WeekRow({
    required this.summary,
    required this.isDark,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg     = _severityColor(summary.total, isDark);
    final pillBg = _severityBg(summary.total, isDark);
    final label  = _severityLabel(summary.total);
    final rowBg  = isDark ? AppColors.dashBg : Colors.white;

    return Material(
      color: rowBg,
      child: InkWell(
        onTap:          onTap,
        borderRadius:   BorderRadius.vertical(
          bottom: isLast ? const Radius.circular(17) : Radius.zero,
        ),
        splashColor:    const Color(0xFF00A8E8).withValues(alpha: 0.06),
        highlightColor: const Color(0xFF00A8E8).withValues(alpha: 0.04),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          summary.label,
                          style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            height:     1.2,
                            color: isDark
                                ? AppColors.dashTextSecondary
                                : const Color(0xFF00435C),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:        pillBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              fontSize:      7,
                              fontWeight:    FontWeight.w900,
                              letterSpacing: 0.5,
                              color:         fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width:  58,
                    height: 28,
                    child:  WeekSparkline(days: summary.days, isDark: isDark),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        summary.total.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize:      19,
                          fontWeight:    FontWeight.w900,
                          letterSpacing: -0.7,
                          height:        1.0,
                          color: isDark
                              ? AppColors.dashTextPrimary
                              : const Color(0xFF00212E),
                        ),
                      ),
                      Text(
                        'alerts',
                        style: TextStyle(
                          fontSize:   7,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.dashTextMuted : const Color(0xFF7A9AAD),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size:  14,
                    color: isDark ? AppColors.dashTextMuted : const Color(0xFFB8DFF0),
                  ),
                ],
              ),
            ),
            if (!isLast) ...[
              Divider(
                color:     isDark ? AppColors.dashSurface : const Color(0xFFDEEDF5),
                height:    1,
                indent:    14,
                endIndent: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}