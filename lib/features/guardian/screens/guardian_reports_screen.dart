import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/guardian_provider.dart';
import '../widgets/guardian_calendar_widget.dart';
import '../widgets/guardian_journal_widget.dart';

class GuardianReportsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const GuardianReportsScreen({super.key, this.onMenuTap});

  @override
  State<GuardianReportsScreen> createState() => _GuardianReportsScreenState();
}

class _GuardianReportsScreenState extends State<GuardianReportsScreen> with AutomaticKeepAliveClientMixin {
  DateTime _selectedDate = DateTime.now();
  late DateTime _displayedMonth;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta, 1);
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Map<String, dynamic>? _getAssessmentForSelectedDate(List<dynamic> assessments) {
    for (var assessment in assessments) {
      if (assessment['createdAt'] != null || assessment['date'] != null) {
        try {
          DateTime dt = DateTime.parse(assessment['createdAt'] ?? assessment['date']).toLocal();
          if (dt.year == _selectedDate.year &&
              dt.month == _selectedDate.month &&
              dt.day == _selectedDate.day) {
            return assessment;
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Widget _buildCustomAppBar(ThemeData theme) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: theme.colorScheme.primary, size: 28),
            onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          Text(
            'Reports Archive',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 48), 
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final provider = context.watch<GuardianProvider>();

    if (provider.targetReportDate != null) {
      final target = provider.targetReportDate!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedDate = target;
            _displayedMonth = DateTime(target.year, target.month, 1);
          });
          context.read<GuardianProvider>().clearTargetReportDate();
        }
      });
    }

    final assignedElders = provider.assignedElders;
    final assessments = provider.assessments;

    final bool hasElder = assignedElders.isNotEmpty;
    final int currentIndex = provider.selectedElderIndex;
    
    final String elderName = (hasElder && currentIndex < assignedElders.length)
        ? '${assignedElders[currentIndex]['firstName']} ${assignedElders[currentIndex]['lastName']}'
        : (hasElder ? '${assignedElders[0]['firstName']} ${assignedElders[0]['lastName']}' : 'No Assigned Elder');

    final selectedAssessment = _getAssessmentForSelectedDate(assessments);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(theme),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: GuardianCalendarWidget(
                        displayedMonth: _displayedMonth,
                        selectedDate: _selectedDate,
                        assessments: assessments,
                        onChangeMonth: _changeMonth,
                        onDateSelected: _onDateSelected,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: GuardianJournalWidget(
                        key: ValueKey(_selectedDate.toIso8601String()),
                        hasElder: hasElder,
                        elderName: elderName,
                        selectedDate: _selectedDate,
                        assessment: selectedAssessment,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}