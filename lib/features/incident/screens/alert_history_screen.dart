import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/dio_client.dart';
import '../../admin/widgets/week_sparkline.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kCategories = ['Fall', 'Agitation', 'Pacing', 'Inactivity', 'Lying Down'];

final _kCategoryColors = {
  'Fall':        AppColors.chartFall,
  'Agitation':   AppColors.chartAgitation,
  'Pacing':      AppColors.chartPacing,
  'Inactivity':  AppColors.chartInactivity,
  'Lying Down':  AppColors.chartLyingDown,
};

// ── Models ────────────────────────────────────────────────────────────────────

class _WeekData {
  final String startISO;
  final String label;
  final int total;
  final List<_DayData> days;

  const _WeekData({
    required this.startISO,
    required this.label,
    required this.total,
    required this.days,
  });
}

class _DayData {
  final String name;
  final String date;
  final int total;
  final Map<String, int> categories;

  const _DayData({
    required this.name,
    required this.date,
    required this.total,
    required this.categories,
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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

Color _severityFg(int total, bool isDark) {
  if (total == 0) return isDark ? const Color(0xFF4CC2EE) : const Color(0xFF0075A2);
  if (total < 10) return isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
  if (total < 20) return isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
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

Future<_WeekData> _fetchWeek(DateTime sunday) async {
  final tz  = DateTime.now().timeZoneName;
  final iso = _iso(sunday);
  final res = await DioClient.instance.get(
    '/incidents/stats/weekly',
    queryParameters: {'weekStart': iso, 'tz': tz},
  );

  final raw    = (res.data as List<dynamic>?) ?? [];
  final byDate = <String, Map<String, dynamic>>{};
  for (final item in raw) {
    final map  = item as Map<String, dynamic>;
    final date = map['date'] as String? ?? '';
    byDate[date] = map;
  }

  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final days = List.generate(7, (i) {
    final d   = sunday.add(Duration(days: i));
    final key = _iso(d);
    final map = byDate[key] ?? {};
    final cats = { for (final c in _kCategories) c: (map[c] as num?)?.toInt() ?? 0 };
    final tot  = cats.values.fold(0, (a, b) => a + b);
    return _DayData(
      name:       dayNames[i],
      date:       key,
      total:      tot,
      categories: cats,
    );
  });

  final total = days.fold(0, (a, d) => a + d.total);
  return _WeekData(startISO: iso, label: _weekLabel(sunday), total: total, days: days);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AlertHistoryScreen extends StatefulWidget {
  final String? initialWeekISO;

  const AlertHistoryScreen({super.key, this.initialWeekISO});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  late DateTime _calendarMonth;
  int? _hoveredWeekIndex;

  List<_WeekData> _historyWeeks = [];
  bool _historyLoading = true;

  _WeekData? _selectedWeek;
  bool _detailLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month, 1);
    _loadHistory();

    if (widget.initialWeekISO != null) {
      final parsed = DateTime.tryParse('${widget.initialWeekISO}T00:00:00');
      if (parsed != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openWeek(parsed));
      }
    }
  }

  List<List<DateTime>> get _calendarGrid {
    final first     = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final gridStart = first.subtract(Duration(days: first.weekday % 7));
    return List.generate(6, (r) =>
      List.generate(7, (c) => gridStart.add(Duration(days: r * 7 + c)))
    );
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final now     = DateTime.now();
      final thisSun = _sundayOfWeek(now);
      final weeks   = await Future.wait(
        List.generate(5, (i) => _fetchWeek(
          thisSun.subtract(Duration(days: i * 7)),
        )),
      );
      if (mounted) {
        setState(() { _historyWeeks = weeks; _historyLoading = false; });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _historyWeeks = []; _historyLoading = false; });
      }
    }
  }

  Future<void> _openWeek(DateTime anchorDate) async {
    final sunday = _sundayOfWeek(anchorDate);
    setState(() { _detailLoading = true; _selectedWeek = null; });
    try {
      final data = await _fetchWeek(sunday);
      if (mounted) {
        setState(() { _selectedWeek = data; _detailLoading = false; });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedWeek = _WeekData(
            startISO: _iso(sunday),
            label:    _weekLabel(sunday),
            total:    0,
            days:     [],
          );
          _detailLoading = false;
        });
      }
    }
  }

  void _closeDetail() => setState(() { _selectedWeek = null; _detailLoading = false; });

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.dashBg : const Color(0xFFF2F8FC);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(context, isDark),
      body: Stack(
        children: [
          _buildBody(isDark),
          if (_detailLoading || _selectedWeek != null)
            _WeekDetailPanel(
              week:      _selectedWeek,
              isLoading: _detailLoading,
              isDark:    isDark,
              onClose:   _closeDetail,
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.dashBg : Colors.white,
      elevation:       0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? AppColors.dashTextPrimary : const Color(0xFF00212E),
          size:  22,
        ),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert History',
            style: TextStyle(
              fontSize:      16,
              fontWeight:    FontWeight.w900,
              letterSpacing: -0.3,
              color: isDark ? AppColors.dashTextPrimary : const Color(0xFF00212E),
            ),
          ),
          Text(
            'Last 5 weeks',
            style: TextStyle(
              fontSize:   10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.dashTextMuted : const Color(0xFF7A9AAD),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color:  isDark ? AppColors.dashSurface : const Color(0xFFDEEDF5),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalendar(isDark),
          const SizedBox(height: 16),
          _buildHistoryList(isDark),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    final cardBg    = isDark ? const Color(0xFF00212E) : Colors.white;
    final borderCol = isDark ? AppColors.dashSurface   : const Color(0xFFDEEDF5);
    final labelCol  = isDark ? AppColors.dashTextMuted : const Color(0xFF7A9AAD);
    final todayStr  = _iso(DateTime.now());
    final grid      = _calendarGrid;

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CalNavBtn(
                  icon: Icons.chevron_left_rounded,
                  isDark: isDark,
                  onTap: () => setState(() {
                    _calendarMonth = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month - 1,
                      1,
                    );
                    _hoveredWeekIndex = null;
                  }),
                ),
                Text(
                  '${_monthName(_calendarMonth.month)} ${_calendarMonth.year}',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.dashTextPrimary : const Color(0xFF00212E),
                  ),
                ),
                _CalNavBtn(
                  icon: Icons.chevron_right_rounded,
                  isDark: isDark,
                  onTap: () => setState(() {
                    _calendarMonth = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month + 1,
                      1,
                    );
                    _hoveredWeekIndex = null;
                  }),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((d) =>
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:      9,
                      fontWeight:    FontWeight.w800,
                      letterSpacing: 0.3,
                      color:         labelCol,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
          ...grid.asMap().entries.map((entry) {
            final ri    = entry.key;
            final week  = entry.value;
            final isHov = _hoveredWeekIndex == ri;

            return GestureDetector(
              onTap: () {
                _hoveredWeekIndex = null;
                _openWeek(week[0]);
              },
              onTapDown:   (_) => setState(() => _hoveredWeekIndex = ri),
              onTapCancel: ()  => setState(() => _hoveredWeekIndex = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin:   const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isHov
                      ? const Color(0xFF00A8E8).withValues(alpha: isDark ? 0.15 : 0.09)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isHov
                      ? Border.all(color: const Color(0xFF00A8E8).withValues(alpha: 0.35))
                      : null,
                ),
                child: Row(
                  children: week.map((date) {
                    final isOther = date.month != _calendarMonth.month;
                    final isToday = _iso(date) == todayStr;
                    return Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: isToday
                            ? Container(
                                width:  24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00A8E8),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    fontSize:   10,
                                    fontWeight: FontWeight.w900,
                                    color:      Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color: isOther
                                      ? (isDark ? const Color(0xFF00435C) : const Color(0xFFCCEDFA))
                                      : (isDark ? AppColors.dashTextPrimary : const Color(0xFF00212E)),
                                ),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildHistoryList(bool isDark) {
    if (_historyLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(color: Color(0xFF00A8E8), strokeWidth: 2.5),
        ),
      );
    }
    if (_historyWeeks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No history available',
            style: TextStyle(
              color:      isDark ? AppColors.dashTextMuted : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'WEEKLY SUMMARY',
            style: TextStyle(
              fontSize:      9,
              fontWeight:    FontWeight.w800,
              letterSpacing: 1.5,
              color: isDark ? AppColors.dashTextMuted : const Color(0xFF7A9AAD),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color:        isDark ? const Color(0xFF00212E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border:       Border.all(
              color: isDark ? AppColors.dashSurface : const Color(0xFFDEEDF5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _historyWeeks.asMap().entries.map((entry) {
              final isLast = entry.key == _historyWeeks.length - 1;
              final wk     = entry.value;
              final fg     = _severityFg(wk.total, isDark);
              final pillBg = _severityBg(wk.total, isDark);
              final days   = wk.days.map((d) => d.categories).toList();

              return Column(
                children: [
                  Material(
                    color: isDark ? const Color(0xFF00212E) : Colors.white,
                    child: InkWell(
                      onTap: () => _openWeek(
                        DateTime.tryParse('${wk.startISO}T00:00:00') ?? DateTime.now(),
                      ),
                      splashColor:    const Color(0xFF00A8E8).withValues(alpha: 0.06),
                      highlightColor: const Color(0xFF00A8E8).withValues(alpha: 0.04),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wk.label,
                                    style: TextStyle(
                                      fontSize:   12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.dashTextPrimary
                                          : const Color(0xFF00435C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:        pillBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _severityLabel(wk.total).toUpperCase(),
                                      style: TextStyle(
                                        fontSize:      8,
                                        fontWeight:    FontWeight.w900,
                                        letterSpacing: 0.6,
                                        color:         fg,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (days.isNotEmpty) ...[
                              SizedBox(
                                width:  64,
                                height: 32,
                                child:  WeekSparkline(days: days, isDark: isDark),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  wk.total.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize:      24,
                                    fontWeight:    FontWeight.w900,
                                    letterSpacing: -0.8,
                                    height:        1.0,
                                    color: isDark
                                        ? AppColors.dashTextPrimary
                                        : const Color(0xFF00212E),
                                  ),
                                ),
                                Text(
                                  'alerts',
                                  style: TextStyle(
                                    fontSize:   8,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.dashTextMuted
                                        : const Color(0xFF7A9AAD),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size:  16,
                              color: isDark
                                  ? AppColors.dashTextMuted
                                  : const Color(0xFFB0C8D4),
                            ),
                          ],
                        ),
                      ),
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
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _monthName(int m) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[m];
  }
}

// ── Calendar nav button ───────────────────────────────────────────────────────

class _CalNavBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _CalNavBtn({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF00A8E8).withValues(alpha: 0.12)
              : const Color(0xFFEEF7FC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF00A8E8)),
      ),
    );
  }
}

// ── Week detail panel ─────────────────────────────────────────────────────────

class _WeekDetailPanel extends StatelessWidget {
  final _WeekData? week;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onClose;

  const _WeekDetailPanel({
    required this.week,
    required this.isLoading,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final panelBg   = isDark ? const Color(0xFF00212E) : Colors.white;
    final borderCol = isDark ? AppColors.dashSurface   : const Color(0xFFDEEDF5);

    return GestureDetector(
      onTap:    onClose,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width:       double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              decoration: BoxDecoration(
                color:        panelBg,
                border:       Border.all(color: borderCol),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin:      const EdgeInsets.only(top: 10, bottom: 14),
                      width:  34,
                      height: 4,
                      decoration: BoxDecoration(
                        color:        isDark ? AppColors.dashSurface : const Color(0xFFDEEDF5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WEEK DETAIL',
                                style: TextStyle(
                                  fontSize:      9,
                                  fontWeight:    FontWeight.w800,
                                  letterSpacing: 1.4,
                                  color: isDark ? AppColors.dashTextMuted : const Color(0xFF7A9AAD),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                week?.label ?? '',
                                style: TextStyle(
                                  fontSize:      16,
                                  fontWeight:    FontWeight.w900,
                                  letterSpacing: -0.3,
                                  color: isDark ? AppColors.dashTextPrimary : const Color(0xFF00212E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width:  32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF00A8E8).withValues(alpha: 0.12)
                                  : const Color(0xFFEEF7FC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size:  16,
                              color: Color(0xFF00A8E8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color:  isDark ? AppColors.dashSurface : const Color(0xFFDEEDF5),
                    height: 1,
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                        color:       Color(0xFF00A8E8),
                        strokeWidth: 2.5,
                      ),
                    )
                  else if (week != null)
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        child: _WeekDetailContent(week: week!, isDark: isDark),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Week detail content ───────────────────────────────────────────────────────

class _WeekDetailContent extends StatelessWidget {
  final _WeekData week;
  final bool isDark;

  const _WeekDetailContent({required this.week, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg     = _severityFg(week.total, isDark);
    final pillBg = _severityBg(week.total, isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF00A8E8).withValues(alpha: 0.07)
                : const Color(0xFFEEF7FC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.dashSurface : const Color(0xFFB8DFF0),
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    week.total.toString(),
                    style: TextStyle(
                      fontSize:      38,
                      fontWeight:    FontWeight.w900,
                      letterSpacing: -1.5,
                      height:        1.0,
                      color: isDark ? AppColors.dashTextPrimary : const Color(0xFF00212E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total Alerts',
                    style: TextStyle(
                      fontSize:      10,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.dashTextMuted : const Color(0xFF7A9AAD),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        pillBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _severityLabel(week.total).toUpperCase(),
                  style: TextStyle(
                    fontSize:      10,
                    fontWeight:    FontWeight.w900,
                    letterSpacing: 0.8,
                    color:         fg,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing:    8,
          runSpacing: 6,
          children: _kCategories.map((cat) {
            final color = _kCategoryColors[cat]!;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
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
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: _buildChart(context),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    if (week.days.isEmpty) {
      return Center(
        child: Text(
          'No data for this week',
          style: TextStyle(
            color:      isDark ? AppColors.dashTextMuted : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final maxY     = week.days.fold<int>(0, (m, d) => d.total > m ? d.total : m);
    final yMax     = (maxY * 1.25).ceilToDouble().clamp(4.0, double.infinity);
    final todayStr = _iso(DateTime.now());

    return BarChart(
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
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= week.days.length) return const SizedBox();
                final isToday = week.days[i].date == todayStr;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    week.days[i].name,
                    style: TextStyle(
                      fontSize:   9,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                      color: isToday
                          ? const Color(0xFF00A8E8)
                          : (isDark ? AppColors.dashTextMuted : const Color(0xFF94A3B8)),
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
            color: isDark
                ? const Color(0xFF00435C).withValues(alpha: 0.45)
                : const Color(0xFFDEEDF5),
            strokeWidth: 1,
            dashArray:   [3, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          week.days.length,
          (i) => _buildBarGroup(i, week.days[i], isDark),
        ),
        groupsSpace: 7,
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int index, _DayData day, bool isDark) {
    double runningY = 0;
    final rods = <BarChartRodData>[];

    for (int ci = 0; ci < _kCategories.length; ci++) {
      final cat   = _kCategories[ci];
      final value = (day.categories[cat] ?? 0).toDouble();
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
        toY:          0.1,
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