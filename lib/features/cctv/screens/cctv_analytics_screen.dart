import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cctv_provider.dart';
import '../widgets/camera_feed_widget.dart';
import '../widgets/alert_card.dart';
import '../widgets/emergency_toast.dart';

class CctvAnalyticsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const CctvAnalyticsScreen({super.key, this.onMenuTap});

  @override
  State<CctvAnalyticsScreen> createState() => _CctvAnalyticsScreenState();
}

class _CctvAnalyticsScreenState extends State<CctvAnalyticsScreen> {
  late CctvProvider _cctvProvider;

  @override
  void initState() {
    super.initState();
    _cctvProvider = context.read<CctvProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cctvProvider.initSocket();
    });
  }

  @override
  void dispose() {
    _cctvProvider.disposeSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<CctvProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildHeader(context, provider, isDark),
                    _buildCameraSelector(provider, isDark),
                    _buildVideoContainer(provider, isDark),
                    const SizedBox(height: 24),
                    _buildAlertsSection(provider, isDark),
                  ],
                ),
              ),
              if (provider.activeToast != null)
                EmergencyToast(alert: provider.activeToast!, provider: provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CctvProvider provider, bool isDark) {
    final activeCount = provider.cameras.where((c) => c.status == 'Active').length;
    final totalCount = provider.cameras.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 20.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: IconButton(
                  icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 22),
                  onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CCTV Hub',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'LIVE MONITORING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00A8E8),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildStatPill('ACTIVE', '$activeCount/$totalCount', false, isDark),
              const SizedBox(width: 12),
              _buildStatPill('ALERTS', '${provider.alerts.length}', true, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, bool isAlert, bool isDark) {
    final bgColor = isAlert 
      ? (isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2)) 
      : (isDark ? const Color(0xFF082F49).withValues(alpha: 0.3) : const Color(0xFFF0F9FF));
    final fgColor = isAlert 
      ? (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48)) 
      : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: fgColor.withValues(alpha: 0.7),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: fgColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSelector(CctvProvider provider, bool isDark) {
    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(vertical: 20.0),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: provider.cameras.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final camera = provider.cameras[index];
          final isActive = camera.cameraId == provider.selectedCameraId;
          final isOnline = camera.status == 'Active';

          return GestureDetector(
            onTap: () => provider.selectCamera(camera.cameraId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutQuart,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF00A8E8), Color(0xFF007BFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00A8E8).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    size: 18,
                    color: isActive ? Colors.white.withValues(alpha: 0.9) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    camera.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? const Color(0xFF10B981) : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                      border: Border.all(
                        color: isActive ? Colors.transparent : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        width: 1.5,
                      ),
                      boxShadow: isOnline
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                blurRadius: 6,
                              )
                            ]
                          : [],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoContainer(CctvProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFF0F172A).withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
            width: 4,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: provider.selectedCamera == null
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 16 / 9,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: provider.cameras.length,
                  itemBuilder: (context, index) => CameraFeedWidget(camera: provider.cameras[index]),
                )
              : AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CameraFeedWidget(camera: provider.selectedCamera!),
                ),
        ),
      ),
    );
  }

  Widget _buildAlertsSection(CctvProvider provider, bool isDark) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Color(0xFF00A8E8), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Analytics Log',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${provider.filteredAlerts.length} EVENTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildFilterChips(provider, isDark),
            Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), thickness: 1.5),
            Expanded(
              child: provider.filteredAlerts.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      physics: const BouncingScrollPhysics(),
                      itemCount: provider.filteredAlerts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return AlertCard(alert: provider.filteredAlerts[index], provider: provider);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(CctvProvider provider, bool isDark) {
    final filters = ['All', 'Unresolved', 'Fall', 'Agitation', 'Pacing', 'Inactivity', 'Lying Down'];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = provider.filterModule == f;
          return GestureDetector(
            onTap: () => provider.setFilterModule(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00A8E8) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.3) : const Color(0xFFF0F9FF),
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.5) : const Color(0xFFE0F2FE), width: 2),
            ),
            child: Icon(Icons.verified_user_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Systems Clear',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No anomalies detected in this session.\nThe environment is secure.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}