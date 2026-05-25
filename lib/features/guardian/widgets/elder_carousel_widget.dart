import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guardian_provider.dart';

class ElderCarouselWidget extends StatefulWidget {
  const ElderCarouselWidget({super.key});

  @override
  State<ElderCarouselWidget> createState() => _ElderCarouselWidgetState();
}

class _ElderCarouselWidgetState extends State<ElderCarouselWidget> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<GuardianProvider>();

    if (provider.assignedElders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: _buildNoElderCard(theme, isDark),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              // Updates the provider so the rest of the app knows which elder is selected
              provider.setSelectedElder(index);
            },
            itemCount: provider.assignedElders.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                child: _buildElderProfileCard(provider.assignedElders[index], theme, isDark),
              );
            },
          ),
        ),
        if (provider.assignedElders.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              provider.assignedElders.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: provider.selectedElderIndex == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: provider.selectedElderIndex == index 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildNoElderCard(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_off_rounded, color: Color(0xFFEF4444), size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'No Assigned Elder',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'There are currently no elders linked to your account. Please contact the facility administrator for assignment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildElderProfileCard(Map<String, dynamic> elder, ThemeData theme, bool isDark) {
    final String elderName = '${elder['firstName']} ${elder['lastName']}';
    final String house = elder['house'] ?? 'Facility Area';
    
    final String attendanceStatus = elder['attendance'] ?? 'Pending Check-in';
    final String notes = elder['notes'] ?? '';
    final bool hasNotes = notes.isNotEmpty;

    Color statusColor;
    IconData statusIcon;
    
    if (attendanceStatus == 'Present') {
      statusColor = isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
      statusIcon = Icons.how_to_reg_rounded;
    } else if (attendanceStatus == 'Not Present') {
      statusColor = isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
      statusIcon = Icons.person_off_rounded;
    } else {
      statusColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
      statusIcon = Icons.pending_actions_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.elderly_rounded, color: theme.colorScheme.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      elderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            house,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily Status: $attendanceStatus',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasNotes ? Icons.sticky_note_2_rounded : Icons.speaker_notes_off_rounded, 
                  color: hasNotes ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), 
                  size: 18
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasNotes ? 'Nurse Note: "$notes"' : 'No monitoring notes entered for today.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: hasNotes ? FontStyle.italic : FontStyle.normal,
                      fontWeight: hasNotes ? FontWeight.w600 : FontWeight.w500,
                      color: hasNotes ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}