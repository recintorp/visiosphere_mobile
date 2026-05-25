import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/admin_audit_provider.dart';
import '../widgets/audit_details_sheet.dart';

class AdminAuditScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const AdminAuditScreen({super.key, this.onMenuTap});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminAuditProvider>().fetchAuditLogs();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String? status, bool isDark) {
    switch (status?.toLowerCase()) {
      case 'success':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
      case 'alert':
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case 'failed':
        return isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
      default:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    }
  }

  Color _getStatusBgColor(String? status, bool isDark) {
    switch (status?.toLowerCase()) {
      case 'success':
        return isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4);
      case 'alert':
        return isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB);
      case 'failed':
        return isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2);
      default:
        return isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'Unknown Time';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      return '${date.month}/${date.day}/${date.year} at $hour:$minute $ampm';
    } catch (_) {
      return isoString;
    }
  }

  void _showFilterSheet(BuildContext context, AdminAuditProvider provider, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter Logs', style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      IconButton(icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('CATEGORY', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        value: provider.filterCategory,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        items: provider.categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.setFilterCategory(val);
                            setSheetState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('STATUS', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        value: provider.filterStatus,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        items: provider.statuses.map((s) => DropdownMenuItem(value: s, child: Text(s == 'All' ? 'All Statuses' : s.toUpperCase(), style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.setFilterStatus(val);
                            setSheetState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('DATE RANGE', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        value: provider.dateFilter,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('All Time', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                          DropdownMenuItem(value: 'today', child: Text('Today', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                          DropdownMenuItem(value: 'week', child: Text('Last 7 Days', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                          DropdownMenuItem(value: 'month', child: Text('Last 30 Days', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            provider.setDateFilter(val);
                            setSheetState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.clearFilters();
                            _searchController.clear();
                            setSheetState(() {});
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Clear Filters', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A8E8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Apply', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLogDetails(BuildContext context, Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
        child: AuditDetailsSheet(log: log),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<AdminAuditProvider>(
          builder: (context, provider, child) {
            final now = DateTime.now();
            final todayCount = provider.logs.where((l) {
              final dStr = l['createdAt'] ?? l['timestamp'];
              if (dStr == null) return false;
              try {
                final d = DateTime.parse(dStr.toString());
                return d.year == now.year && d.month == now.month && d.day == now.day;
              } catch (_) {
                return false;
              }
            }).length;

            return Column(
              children: [
                _buildCustomAppBar(isDark),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: const BorderRadius.only(bottomRight: Radius.circular(60))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInDown(duration: const Duration(milliseconds: 800), child: Text('Compliance Tracking', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))),
                          FadeInDown(delay: const Duration(milliseconds: 100), child: Text('Audit Trail & Logs', style: TextStyle(fontFamily: 'Montserrat', fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBadge(
                        'Total Logs',
                        provider.logs.length.toString(),
                        isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                        isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : const Color(0xFFF0F9FF),
                        isDark,
                      ),
                      _buildStatBadge(
                        'Today',
                        todayCount.toString(),
                        isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
                        isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFF0FDF4),
                        isDark,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => provider.setSearchQuery(val),
                            style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w500, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: 'Search event, actor...',
                              hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Montserrat'),
                              prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                        child: IconButton(
                          icon: Icon(Icons.tune_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          onPressed: () => _showFilterSheet(context, provider, isDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFF00A8E8), borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          icon: const Icon(Icons.download_rounded, color: Colors.white),
                          onPressed: () async {
                            final path = await provider.exportToCSV();
                            if (context.mounted) {
                              if (path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: $path', style: const TextStyle(fontFamily: 'Montserrat')), backgroundColor: const Color(0xFF10B981)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to export CSV or list is empty.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)));
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Showing ${provider.filteredLogs.length} results', style: const TextStyle(fontFamily: 'Montserrat', color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                      if (provider.filterCategory != 'All' || provider.filterStatus != 'All' || provider.dateFilter != 'all')
                        GestureDetector(
                          onTap: () {
                            provider.clearFilters();
                            _searchController.clear();
                          },
                          child: Text('Clear Filters', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48), fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                ),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A8E8)))
                      : provider.filteredLogs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 64, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1).withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text('No logs found.', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                              itemCount: provider.filteredLogs.length,
                              itemBuilder: (context, index) {
                                final log = provider.filteredLogs[index];
                                final statusColor = _getStatusColor(log['status']?.toString(), isDark);
                                final statusBgColor = _getStatusBgColor(log['status']?.toString(), isDark);

                                return FadeInUp(
                                  duration: const Duration(milliseconds: 300),
                                  delay: Duration(milliseconds: (index < 10 ? index : 0) * 40),
                                  child: GestureDetector(
                                    onTap: () => _showLogDetails(context, log),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 8, offset: const Offset(0, 4))],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(_formatDate(log['createdAt']?.toString() ?? log['timestamp']?.toString()), style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
                                                  child: Text((log['status']?.toString() ?? 'Unknown').toUpperCase(), style: TextStyle(fontFamily: 'Montserrat', color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(log['event']?.toString() ?? 'Unknown Event', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.person_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                                const SizedBox(width: 6),
                                                Text(log['actorName']?.toString() ?? 'System', style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                                  child: Text(log['category']?.toString() ?? 'General', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                                ),
                                                Row(
                                                  children: [
                                                    Text('View Details', style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))),
                                                    const SizedBox(width: 4),
                                                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color, Color bgColor, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2))),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontFamily: 'Montserrat', fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.8), letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}