import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/admin_audit_provider.dart';

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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'alert':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.blueGrey;
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

  String _prettyPrintJson(dynamic jsonObj) {
    if (jsonObj == null) return '';
    try {
      if (jsonObj is String) {
        if (jsonObj.isEmpty) return '';
        final parsed = jsonDecode(jsonObj);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      }
      if (jsonObj is Map && jsonObj.isEmpty) return '';
      return const JsonEncoder.withIndent('  ').convert(jsonObj);
    } catch (_) {
      return jsonObj.toString();
    }
  }

  void _showFilterSheet(BuildContext context, AdminAuditProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF001F2D))),
                      IconButton(icon: const Icon(Icons.close, color: Colors.blueGrey), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: provider.filterCategory,
                        items: provider.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.setFilterCategory(val);
                            setSheetState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: provider.filterStatus,
                        items: provider.statuses.map((s) => DropdownMenuItem(value: s, child: Text(s == 'All' ? 'All Statuses' : s.toUpperCase()))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.setFilterStatus(val);
                            setSheetState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('DATE RANGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: provider.dateFilter,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Time')),
                          DropdownMenuItem(value: 'today', child: Text('Today')),
                          DropdownMenuItem(value: 'week', child: Text('Last 7 Days')),
                          DropdownMenuItem(value: 'month', child: Text('Last 30 Days')),
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
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('Clear Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0FB2EA), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final oldVals = _prettyPrintJson(log['oldValues']);
    final newVals = _prettyPrintJson(log['newValues']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Log Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF001F2D))),
                IconButton(icon: const Icon(Icons.close, color: Colors.blueGrey), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Category', log['category']?.toString() ?? 'N/A'),
                    _buildDetailRow('Event', log['event']?.toString() ?? 'N/A'),
                    _buildDetailRow('Actor', log['actorName']?.toString() ?? 'N/A'),
                    _buildDetailRow('Timestamp', _formatDate(log['createdAt']?.toString() ?? log['timestamp']?.toString())),
                    _buildDetailRow('Status', (log['status']?.toString() ?? 'Unknown').toUpperCase(), color: _getStatusColor(log['status']?.toString())),
                    _buildDetailRow('Purpose', log['purpose']?.toString() ?? 'N/A'),
                    if (oldVals.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('PREVIOUS VALUES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                        child: Text(oldVals, style: const TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontSize: 12)),
                      ),
                    ],
                    if (newVals.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('NEW VALUES / DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                        child: Text(newVals, style: const TextStyle(color: Color(0xFF4ADE80), fontFamily: 'monospace', fontSize: 12)),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color ?? const Color(0xFF001F2D), fontSize: 14))),
        ],
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
          Image.asset('assets/images/visio.png', height: 36, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported)),
          const Icon(Icons.notifications_none, color: Color(0xFF0066CC)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
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
            final alertCount = provider.logs.where((l) => (l['status']?.toString().toLowerCase()) == 'alert').length;

            return Column(
              children: [
                _buildCustomAppBar(),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: const BoxDecoration(color: Color(0xFFE8F4FD), borderRadius: BorderRadius.only(bottomRight: Radius.circular(60))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInDown(duration: const Duration(milliseconds: 800), child: const Text('Compliance Tracking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF001F2D)))),
                          FadeInDown(delay: const Duration(milliseconds: 100), child: const Text('Audit Trail & Logs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0066CC)))),
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
                      _buildStatBadge('Total Logs', provider.logs.length.toString(), Colors.blue),
                      _buildStatBadge('Today', todayCount.toString(), Colors.green),
                      _buildStatBadge('Alerts', alertCount.toString(), Colors.orange),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2))),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => provider.setSearchQuery(val),
                            decoration: const InputDecoration(hintText: 'Search logs...', hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 14), prefixIcon: Icon(Icons.search, color: Colors.blueGrey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFF0FB2EA), borderRadius: BorderRadius.circular(12)),
                        child: IconButton(icon: const Icon(Icons.filter_list, color: Colors.white), onPressed: () => _showFilterSheet(context, provider)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2))),
                        child: IconButton(
                          icon: const Icon(Icons.download, color: Color(0xFF001F2D)),
                          onPressed: () async {
                            final path = await provider.exportToCSV();
                            if (context.mounted) {
                              if (path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: $path')));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to export CSV or list is empty.')));
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Showing ${provider.filteredLogs.length} results', style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                      if (provider.filterCategory != 'All' || provider.filterStatus != 'All' || provider.dateFilter != 'all')
                        GestureDetector(
                          onTap: () {
                            provider.clearFilters();
                            _searchController.clear();
                          },
                          child: const Text('Clear Filters', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                ),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0FB2EA)))
                      : provider.filteredLogs.isEmpty
                          ? const Center(child: Text('No logs found.', style: TextStyle(color: Colors.blueGrey)))
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                              itemCount: provider.filteredLogs.length,
                              itemBuilder: (context, index) {
                                final log = provider.filteredLogs[index];
                                final statusColor = _getStatusColor(log['status']?.toString());
                                return FadeInUp(
                                  duration: const Duration(milliseconds: 300),
                                  delay: Duration(milliseconds: (index < 10 ? index : 0) * 50),
                                  child: GestureDetector(
                                    onTap: () => _showLogDetails(context, log),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
                                        boxShadow: [BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(_formatDate(log['createdAt']?.toString() ?? log['timestamp']?.toString()), style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                                  child: Text((log['status']?.toString() ?? 'Unknown').toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(log['event']?.toString() ?? 'Unknown Event', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F2D))),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.person_outline, size: 14, color: Colors.blueGrey),
                                                const SizedBox(width: 4),
                                                Text(log['actorName']?.toString() ?? 'System', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                                                  child: Text(log['category']?.toString() ?? 'General', style: const TextStyle(color: Color(0xFF0066CC), fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                                const Row(
                                                  children: [
                                                    Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0FB2EA))),
                                                    Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF0FB2EA)),
                                                  ],
                                                ),
                                              ],
                                            )
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

  Widget _buildStatBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}