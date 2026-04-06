import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'providers/guardian_provider.dart';

class GuardianHomeScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const GuardianHomeScreen({super.key, this.onMenuTap});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  bool _isLoadingSync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuardianProvider>().fetchGuardianData();
    });
  }

  void _handleSync() async {
    setState(() {
      _isLoadingSync = true;
    });
    
    await context.read<GuardianProvider>().fetchGuardianData();
    
    if (mounted) {
      context.read<GuardianProvider>().setSynced(true);
      setState(() {
        _isLoadingSync = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      return dateStr.split('T')[0];
    } catch (e) {
      return dateStr;
    }
  }

  String _formatGender(String? g) {
    if (g == 'F' || g == 'f') return 'Female';
    if (g == 'M' || g == 'm') return 'Male';
    return g ?? '-';
  }

  String _getLastAssessmentTime(List<dynamic> assessments) {
    if (assessments.isEmpty) return 'No reports yet';
    try {
      final lastAssessment = assessments.first;
      final DateTime dt = DateTime.parse(lastAssessment['createdAt']).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      
      return 'Today, $hour:$minute $period';
    } catch (e) {
      return 'No reports yet';
    }
  }

  void _showElderSelector(BuildContext context, List<dynamic> elders, int currentIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Resident to Monitor',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF001F2D)),
              ),
              const SizedBox(height: 15),
              ...List.generate(elders.length, (index) {
                final elder = elders[index];
                final isSelected = index == currentIndex;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? const Color(0xFF0FB2EA) : const Color(0xFFE8F4FD),
                    child: Icon(Icons.person, color: isSelected ? Colors.white : const Color(0xFF0FB2EA)),
                  ),
                  title: Text(
                    '${elder['firstName']} ${elder['lastName']}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: const Color(0xFF001F2D),
                    ),
                  ),
                  subtitle: Text('ID: ${elder['residentId']}'),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF0FB2EA)) : null,
                  onTap: () {
                    context.read<GuardianProvider>().setSelectedElder(index);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
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
            icon: const Icon(Icons.menu, color: Color(0xFF0FB2EA)),
            onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          Image.asset(
            'assets/images/visio.png',
            height: 36,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, color: Color(0xFF0FB2EA)),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                color: const Color(0xFF0FB2EA),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuardianProvider>();
    final guardianData = provider.guardianData;
    final assessments = provider.assessments;
    
    final String fullName = guardianData != null 
        ? '${guardianData['firstName']} ${guardianData['lastName']}'
        : 'Loading...';
    final String guardianId = guardianData != null ? guardianData['guardianId'] : '...';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomAppBar(),
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 140,
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
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FadeInDown(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 100),
                                child: Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF001F2D),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FadeInDown(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 200),
                                child: Text(
                                  'ID: $guardianId',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0FB2EA),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FadeInRight(
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0FB2EA), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0FB2EA).withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person, color: Color(0xFF0FB2EA), size: 30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 300),
                      child: _buildSyncOrElderCard(provider),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 400),
                      child: const Text(
                        'Facility Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001F2D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 500),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildOverviewCard(
                              Icons.assignment_turned_in_outlined,
                              'Last Assessment',
                              _getLastAssessmentTime(assessments),
                              const Color(0xFF0FB2EA),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildOverviewCard(
                              Icons.access_time,
                              'Current Time',
                              _formatCurrentTime(),
                              const Color(0xFF0066CC),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 600),
                      child: const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001F2D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 700),
                      child: _buildAccountInfoCard(guardianData),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncOrElderCard(GuardianProvider provider) {
    Widget activeChild;

    if (provider.isSynced) {
      if (provider.assignedElders.isNotEmpty) {
        activeChild = _buildElderProfileCard(
          provider.assignedElders[provider.selectedElderIndex],
          provider.assignedElders.length > 1,
          provider.assignedElders,
          provider.selectedElderIndex,
        );
      } else {
        activeChild = _buildNoElderCard();
      }
    } else {
      activeChild = _buildSyncBanner();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: activeChild,
    );
  }

  Widget _buildSyncBanner() {
    return Container(
      key: const ValueKey('sync_banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0FB2EA), Color(0xFF0066CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0FB2EA).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sync, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned Elder Sync',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sync daily summaries and nurse comments.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoadingSync ? null : _handleSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0066CC),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: _isLoadingSync
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0066CC),
                    ),
                  )
                : const Text(
                    'Sync Now',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoElderCard() {
    return Container(
      key: const ValueKey('no_elder'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_off_outlined, color: Colors.redAccent, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Assigned Elder',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001F2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are currently no elders linked to your account. Please contact the facility admin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildElderProfileCard(Map<String, dynamic> elder, bool hasMultiple, List<dynamic> allElders, int currentIndex) {
    final String elderName = '${elder['firstName']} ${elder['lastName']}';
    final String house = elder['house'] ?? 'Monitored Area';

    return Container(
      key: ValueKey(elder['residentId']),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0FB2EA).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.elderly, color: Color(0xFF0FB2EA), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      elderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF001F2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.location_on, size: 12, color: Colors.blueGrey),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            house,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasMultiple)
                IconButton(
                  onPressed: () => _showElderSelector(context, allElders, currentIndex),
                  icon: const Icon(Icons.swap_horiz, color: Color(0xFF0FB2EA)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Switch Elder',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.blueGrey.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildElderStat(Icons.favorite, 'Vitals', 'Stable', Colors.redAccent),
              Container(height: 30, width: 1, color: Colors.blueGrey.withValues(alpha: 0.1)),
              _buildElderStat(Icons.restaurant, 'Meals', 'Completed', Colors.orange),
              Container(height: 30, width: 1, color: Colors.blueGrey.withValues(alpha: 0.1)),
              _buildElderStat(Icons.mood, 'Mood', 'Cheerful', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElderStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001F2D),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001F2D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(Map<String, dynamic>? guardianData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('First Name', guardianData?['firstName'] ?? '-'),
          Divider(color: Colors.blueGrey.withValues(alpha: 0.1), height: 24),
          _buildInfoRow('Middle Name', guardianData?['middleName'] ?? '-'),
          Divider(color: Colors.blueGrey.withValues(alpha: 0.1), height: 24),
          _buildInfoRow('Last Name', guardianData?['lastName'] ?? '-'),
          Divider(color: Colors.blueGrey.withValues(alpha: 0.1), height: 24),
          _buildInfoRow('Gender', _formatGender(guardianData?['gender'])),
          Divider(color: Colors.blueGrey.withValues(alpha: 0.1), height: 24),
          _buildInfoRow('Birthday', _formatDate(guardianData?['birthday'])),
          Divider(color: Colors.blueGrey.withValues(alpha: 0.1), height: 24),
          _buildInfoRow('Email Address', guardianData?['email'] ?? '-'),
          Divider(color: Colors.blueGrey.withValues(alpha: 0.1), height: 24),
          _buildInfoRow('Contact Number', guardianData?['phone'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.blueGrey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001F2D),
          ),
        ),
      ],
    );
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    int hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $ampm';
  }
}