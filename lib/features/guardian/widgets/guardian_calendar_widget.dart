import 'package:flutter/material.dart';

class GuardianCalendarWidget extends StatefulWidget {
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final List<dynamic> assessments;
  final Function(int) onChangeMonth;
  final Function(DateTime) onDateSelected;

  const GuardianCalendarWidget({
    super.key,
    required this.displayedMonth,
    required this.selectedDate,
    required this.assessments,
    required this.onChangeMonth,
    required this.onDateSelected,
  });

  @override
  State<GuardianCalendarWidget> createState() => _GuardianCalendarWidgetState();
}

class _GuardianCalendarWidgetState extends State<GuardianCalendarWidget> {
  // New state to track if the calendar is open or collapsed
  bool _isExpanded = true;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  Set<int> _getDaysWithReports() {
    Set<int> daysWithReports = {};
    for (var a in widget.assessments) {
      if (a['createdAt'] != null || a['date'] != null) {
        try {
          DateTime dt = DateTime.parse(a['createdAt'] ?? a['date']).toLocal();
          if (dt.year == widget.displayedMonth.year && dt.month == widget.displayedMonth.month) {
            daysWithReports.add(dt.day);
          }
        } catch (_) {
          // Ignore invalid dates
        }
      }
    }
    return daysWithReports;
  }

  void _toggleCalendar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final daysWithReports = _getDaysWithReports();
    final int daysInMonth = DateUtils.getDaysInMonth(widget.displayedMonth.year, widget.displayedMonth.month);
    final int firstDayOffset = DateTime(widget.displayedMonth.year, widget.displayedMonth.month, 1).weekday % 7;
    final DateTime today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Month/Year, Collapse Button, and Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Wrap the title and chevron in a GestureDetector for easy tapping
              GestureDetector(
                onTap: _toggleCalendar,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      '${_monthNames[widget.displayedMonth.month - 1]} ${widget.displayedMonth.year}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0 : 0.5, // Rotates the chevron 180 degrees when collapsed
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded, 
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Only show navigation arrows when the calendar is expanded
              AnimatedOpacity(
                opacity: _isExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: _isExpanded ? () => widget.onChangeMonth(-1) : null,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: _isExpanded ? () => widget.onChangeMonth(1) : null,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // The Expandable Calendar Grid
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 24),
                      // Weekdays Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _weekDays.map((d) => SizedBox(
                          width: 32,
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12, 
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8), 
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Calendar Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: daysInMonth + firstDayOffset,
                        itemBuilder: (context, index) {
                          if (index < firstDayOffset) {
                            return const SizedBox.shrink();
                          }

                          int day = index - firstDayOffset + 1;
                          bool isSelected = widget.selectedDate.year == widget.displayedMonth.year && 
                                            widget.selectedDate.month == widget.displayedMonth.month && 
                                            widget.selectedDate.day == day;
                          
                          bool isToday = today.year == widget.displayedMonth.year && 
                                         today.month == widget.displayedMonth.month && 
                                         today.day == day;

                          bool hasReport = daysWithReports.contains(day);

                          return GestureDetector(
                            onTap: () => widget.onDateSelected(DateTime(widget.displayedMonth.year, widget.displayedMonth.month, day)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? theme.colorScheme.primary 
                                    : (isToday ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isToday && !isSelected 
                                      ? theme.colorScheme.primary.withValues(alpha: 0.5) 
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: (isSelected || isToday) ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected 
                                          ? theme.colorScheme.onPrimary 
                                          : (isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                                    ),
                                  ),
                                  if (hasReport)
                                    Positioned(
                                      bottom: 4,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white : const Color(0xFFF59E0B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity), // Maintains width when collapsed
          ),
        ],
      ),
    );
  }
}