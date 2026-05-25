import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/admin_assessments_provider.dart';
import '../providers/admin_elders_provider.dart';
import '../providers/admin_dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/assessment_history_card.dart';
import '../widgets/assessment_builder_sheet.dart';

class AdminAssessmentsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final bool isNurseView;

  const AdminAssessmentsScreen({super.key, this.onMenuTap, this.isNurseView = false});

  @override
  State<AdminAssessmentsScreen> createState() => _AdminAssessmentsScreenState();
}

class _AdminAssessmentsScreenState extends State<AdminAssessmentsScreen> {
  String? _selectedResidentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        final dashboardProvider = context.read<AdminDashboardProvider>();
        
        bool isSimulatingAdmin = widget.isNurseView && authProvider.userRole == 'Facility Admin';
        
        context.read<AdminEldersProvider>().fetchResidents(
          userRole: isSimulatingAdmin ? 'Nurse' : authProvider.userRole,
          userId: isSimulatingAdmin ? dashboardProvider.nurseId : authProvider.userId,
        );
      }
    });
  }

  void _openBuilderSheet(BuildContext context, Map<String, dynamic>? existingReport) {
    final resident = context.read<AdminEldersProvider>().residents.firstWhere(
      (r) => (r['_id'] ?? r['residentId']) == _selectedResidentId,
      orElse: () => <String, dynamic>{},
    );
    final authProvider = context.read<AuthProvider>();
    final provider = context.read<AdminAssessmentsProvider>();
    final dashboardProvider = context.read<AdminDashboardProvider>();

    bool isSimulatingAdmin = widget.isNurseView && authProvider.userRole == 'Facility Admin';

    if (existingReport != null) {
      provider.loadReportForEditing(existingReport);
    } else {
      provider.resetBuilder();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssessmentBuilderSheet(
        residentId: _selectedResidentId ?? '',
        residentName: '${resident['firstName'] ?? ''} ${resident['lastName'] ?? ''}'.trim(),
        authorId: isSimulatingAdmin ? (dashboardProvider.nurseId ?? 'N-SECURE') : (authProvider.userId ?? 'A-001'),
        authorName: isSimulatingAdmin ? (dashboardProvider.nurseName ?? 'Nurse') : (authProvider.userName ?? 'System Admin'),
      ),
    );
  }

  Widget _buildCustomAppBar(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: isDark ? Colors.white : const Color(0xFF00A8E8)),
            onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          Image.asset('assets/images/visio.png', height: 36, color: isDark ? Colors.white : null, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported)),
          Icon(Icons.notifications_none, color: isDark ? Colors.white : const Color(0xFF00A8E8)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(60)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(child: Text('Daily Summary', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF00212E)))),
              FadeInDown(delay: const Duration(milliseconds: 100), child: Text('Assessments & Reports', style: TextStyle(fontFamily: 'Montserrat', fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResidentSelector(List<dynamic> residents, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), width: 1.5),
          boxShadow: [
            BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ]
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            hint: Text('Select a Resident...', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            value: _selectedResidentId,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
            items: residents.map((r) {
              final id = r['_id'] ?? r['residentId'];
              return DropdownMenuItem<String>(
                value: id.toString(),
                child: Text('${r['firstName']} ${r['lastName']}', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedResidentId = val;
              });
              if (val != null) context.read<AdminAssessmentsProvider>().fetchAssessments(val);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentHistory(AdminAssessmentsProvider provider, bool isDark) {
    if (_selectedResidentId == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF00A8E8).withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : const Color(0xFFF0F9FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.folder_shared_rounded, size: 64, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Resident Selected',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please choose a resident from the dropdown menu above to securely view or add new daily assessment reports.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Pulse(
                    infinite: true,
                    child: Icon(Icons.keyboard_double_arrow_up_rounded, size: 32, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00A8E8)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Resident History', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF00212E))),
              ElevatedButton.icon(
                onPressed: () => _openBuilderSheet(context, null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Report', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A8E8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        if (provider.assessments.isEmpty)
          Expanded(
            child: Center(
              child: FadeIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Icon(Icons.description_outlined, size: 48, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),
                    Text('No reports found.', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Text('Click "New Report" to create the first entry.', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: provider.assessments.length,
              itemBuilder: (context, index) {
                final report = provider.assessments[index];
                return AssessmentHistoryCard(
                  assessment: report,
                  residentId: _selectedResidentId!,
                  isNurseView: widget.isNurseView,
                  onEdit: () => _openBuilderSheet(context, report),
                  onDelete: () => provider.deleteAssessment(report['_id'], _selectedResidentId!),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final residents = context.watch<AdminEldersProvider>().residents;
    final assessmentsProvider = context.watch<AdminAssessmentsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(isDark),
            _buildHeader(isDark),
            _buildResidentSelector(residents, isDark),
            Expanded(
              child: _buildAssessmentHistory(assessmentsProvider, isDark),
            ),
          ],
        ),
      ),
    );
  }
}