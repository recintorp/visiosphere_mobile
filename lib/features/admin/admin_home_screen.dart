import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/admin_dashboard_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final bool isNurseView;

  const AdminHomeScreen({super.key, this.onMenuTap, this.isNurseView = false});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminDashboardProvider>().fetchDashboardData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<AdminDashboardProvider>().fetchDashboardData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomAppBar(),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(60),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeInDown(
                                  duration: const Duration(milliseconds: 800),
                                  child: const Text(
                                    'Overview',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF001F2D),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FadeInDown(
                                  duration: const Duration(milliseconds: 800),
                                  delay: const Duration(milliseconds: 100),
                                  child: Text(
                                    widget.isNurseView ? 'Nurse Hub' : 'Admin Dashboard',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0066CC),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FadeInDown(
                                  duration: const Duration(milliseconds: 800),
                                  delay: const Duration(milliseconds: 200),
                                  child: const Text(
                                    'Integrated Elderly Care\nManagement System',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: FadeInRight(
                              duration: const Duration(milliseconds: 800),
                              child: Image.asset(
                                'assets/images/visiologo.png',
                                height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(height: 100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Consumer<AdminDashboardProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF0066CC),
                            ),
                          ),
                        );
                      }

                      if (provider.errorMessage != null) {
                        return Center(
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(provider.errorMessage!,
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: provider.retry,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 100),
                            child: _buildStatCard(
                              'Total Elders',
                              provider.totalElders.toString(),
                              Icons.people_alt,
                              const Color(0xFF0066CC),
                              '↑ 0% from last month',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 200),
                            child: _buildStatCard(
                              'Active Nurses',
                              provider.activeNurses.toString(),
                              Icons.person_outline,
                              const Color(0xFF0066CC),
                              '↑ 5 today',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 300),
                            child: _buildStatCard(
                              'Alerts Today',
                              provider.alertsToday.toString().padLeft(2, '0'),
                              Icons.email_outlined,
                              const Color(0xFF0066CC),
                              '↑ 2 new',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 400),
                            child: _buildActivityCard(provider.recentActivities),
                          ),
                          const SizedBox(height: 40),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF0066CC)),
            onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          Image.asset(
            'assets/images/visio.png',
            height: 36,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, color: Color(0xFF0066CC)),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                color: const Color(0xFF0066CC),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color iconColor, String trend, Color trendColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF001F2D),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ],
          ),
          Divider(
            color: Colors.blueGrey.withValues(alpha: 0.2),
            height: 24,
            thickness: 1,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF001F2D),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: trendColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(List<dynamic> activities) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF001F2D),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.show_chart,
                    color: Color(0xFF0066CC), size: 24),
              ),
            ],
          ),
          Divider(
            color: Colors.blueGrey.withValues(alpha: 0.2),
            height: 24,
            thickness: 1,
          ),
          if (activities.isEmpty)
            const Text(
              'No recent activity.',
              style: TextStyle(color: Colors.blueGrey, fontSize: 13),
            )
          else
            ...activities.map((activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 4,
                        backgroundColor: Color(0xFF00B4D8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${activity['actorName'] ?? 'System'} ${activity['event']?.toString().toLowerCase() ?? 'performed an action'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}