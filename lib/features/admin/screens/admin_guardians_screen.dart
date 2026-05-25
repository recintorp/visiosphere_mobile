import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/admin_guardians_provider.dart';
import '../widgets/guardian_card.dart';
import '../widgets/provision_guardian_modal.dart';
import '../widgets/edit_guardian_modal.dart';
import '../widgets/assign_elders_modal.dart';
import '../widgets/delete_guardian_dialog.dart';

class AdminGuardiansScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final bool isNurseView;

  const AdminGuardiansScreen({super.key, this.onMenuTap, this.isNurseView = false});

  @override
  State<AdminGuardiansScreen> createState() => _AdminGuardiansScreenState();
}

class _AdminGuardiansScreenState extends State<AdminGuardiansScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedGuardians = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<AdminGuardiansProvider>();
        provider.fetchGuardians();
        provider.fetchResidents();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProvisionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProvisionGuardianModal(),
    );
  }

  void _showEditModal(Map<String, dynamic> guardian) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditGuardianModal(guardian: guardian),
    ).then((_) {
      if (mounted) {
        setState(() => _selectedGuardians.clear());
      }
    });
  }

  void _showAssignModal(Map<String, dynamic> guardian) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignEldersModal(guardian: guardian),
    );
  }

  void _showDeleteDialog(Set<String> ids) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteGuardianDialog(guardianIds: ids),
    );
    if (mounted) {
      setState(() => _selectedGuardians.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: widget.isNurseView 
        ? null 
        : FloatingActionButton.extended(
            onPressed: _showProvisionModal,
            backgroundColor: const Color(0xFF00A8E8),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
            label: const Text(
              'Provision Account',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomAppBar(isDark),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
                        : [const Color(0xFFE8F4FD), const Color(0xFFF8FAFC)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  right: -20,
                  top: 10,
                  child: Opacity(
                    opacity: isDark ? 0.3 : 0.6,
                    child: Image.asset(
                      'assets/images/logogo.png',
                      height: 140,
                      width: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const SizedBox(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF00A8E8).withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
                          ),
                          child: Text(
                            'Account Management',
                            style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), letterSpacing: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'Guardians Directory',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 32, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: -0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'Manage family accounts and elder assignments.',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (_selectedGuardians.isNotEmpty)
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : const Color(0xFFE1F5FE),
                      border: Border.all(color: const Color(0xFF00A8E8)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedGuardians.length} account(s) selected',
                              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00435C)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (_selectedGuardians.length == 1)
                              InkWell(
                                onTap: () {
                                  final id = _selectedGuardians.first;
                                  final provider = context.read<AdminGuardiansProvider>();
                                  final guardian = provider.guardians.firstWhere((g) => g['guardianId'] == id || g['_id'] == id);
                                  _showEditModal(guardian);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white, 
                                    borderRadius: BorderRadius.circular(6), 
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                                  ),
                                  child: Text('Edit', style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                                ),
                              ),
                            if (!widget.isNurseView) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showDeleteDialog(_selectedGuardians),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2), 
                                    borderRadius: BorderRadius.circular(6), 
                                    border: Border.all(color: isDark ? const Color(0xFF881337).withValues(alpha: 0.5) : const Color(0xFFFDA4AF))
                                  ),
                                  child: Text('Delete', style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48))),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => setState(() => _selectedGuardians.clear()),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(Icons.close_rounded, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => context.read<AdminGuardiansProvider>().setSearchTerm(value),
                  style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search by ID, Name, or Email...',
                    hintStyle: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Consumer<AdminGuardiansProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Filters & Sorting', style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildSortPill('A-Z ↓', 'asc', provider, isDark),
                          _buildSortPill('Z-A ↑', 'desc', provider, isDark),
                          Container(width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                          _buildStatusFilterPill('ALL', provider, isDark),
                          _buildStatusFilterPill('ACTIVE', provider, isDark),
                          _buildStatusFilterPill('INACTIVE', provider, isDark),
                          _buildStatusFilterPill('PENDING', provider, isDark),
                        ],
                      ),
                    ),
                  ],
                );
              }
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Consumer<AdminGuardiansProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00A8E8)));
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 48),
                          const SizedBox(height: 16),
                          Text(provider.errorMessage!, style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: provider.fetchGuardians,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A8E8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Retry', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }

                  final guardians = provider.filteredGuardians;

                  if (guardians.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.family_restroom_rounded, size: 64, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          const SizedBox(height: 16),
                          Text('No guardians found.', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: provider.fetchGuardians,
                    color: const Color(0xFF00A8E8),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
                      itemCount: guardians.length,
                      itemBuilder: (context, index) {
                        final guardian = guardians[index];
                        final guardianId = guardian['guardianId'] ?? guardian['_id'];
                        final isSelected = _selectedGuardians.contains(guardianId);

                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          child: GuardianCard(
                            guardian: guardian,
                            isSelected: isSelected,
                            onSelect: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedGuardians.add(guardianId);
                                } else {
                                  _selectedGuardians.remove(guardianId);
                                }
                              });
                            },
                            onTap: () {
                              if (_selectedGuardians.isNotEmpty) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedGuardians.remove(guardianId);
                                  } else {
                                    _selectedGuardians.add(guardianId);
                                  }
                                });
                              } else {
                                _showEditModal(guardian);
                              }
                            },
                            onAssignElders: () => _showAssignModal(guardian),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortPill(String label, String sortValue, AdminGuardiansProvider provider, bool isDark) {
    final isActive = provider.sortOrder == sortValue;
    return GestureDetector(
      onTap: () => provider.toggleSortOrder(sortValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A)) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          boxShadow: isActive 
            ? [BoxShadow(color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A)).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] 
            : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: isActive ? (isDark ? const Color(0xFF0F172A) : Colors.white) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterPill(String status, AdminGuardiansProvider provider, bool isDark) {
    final isActive = provider.statusFilter == status;
    return GestureDetector(
      onTap: () => provider.setStatusFilter(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00A8E8) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        ),
        alignment: Alignment.center,
        child: Text(
          status,
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: isActive ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F4FD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 28),
            onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          Image.asset(
            'assets/images/visio.png',
            height: 34,
            fit: BoxFit.contain,
            color: isDark ? Colors.white : null,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.security, color: Color(0xFF00A8E8), size: 32),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, size: 28, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757),
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}