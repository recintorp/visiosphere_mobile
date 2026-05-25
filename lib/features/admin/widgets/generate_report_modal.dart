import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/admin_elders_provider.dart';

class GenerateReportModal extends StatefulWidget {
  const GenerateReportModal({super.key});

  @override
  State<GenerateReportModal> createState() => _GenerateReportModalState();
}

class _GenerateReportModalState extends State<GenerateReportModal> {
  bool _isSaving = false;

  void _handleSaveAndDownload() async {
    setState(() => _isSaving = true);
    final provider = context.read<AdminEldersProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final reportData = {
      'reportDate': DateTime.now().toIso8601String(),
      'totalResidents': provider.houseHeadcount,
      'totalPresent': provider.presentCount,
      'totalNotPresent': provider.notPresentCount,
      'housesSummary': provider.houses.map((houseName) {
        final hRes = provider.residents.where((r) => r['house'] == houseName).toList();
        return {
          'house': houseName,
          'headcount': hRes.length,
          'present': hRes.where((r) => r['attendance'] == 'Present').length,
          'notPresent': hRes.where((r) => r['attendance'] == 'Not Present' || r['attendance'] == null).length,
        };
      }).toList(),
      'absentResidents': provider.residents
          .where((r) => r['attendance'] == 'Not Present' || r['attendance'] == null)
          .map((r) {
            final firstName = r['firstName'] ?? '';
            final lastName = r['lastName'] ?? '';
            return {
              'residentId': r['residentId'],
              'name': '$firstName $lastName',
              'house': r['house'],
            };
          }).toList(),
      'notesSnapshot': provider.residents
          .where((r) => (r['notes'] ?? '').toString().trim().isNotEmpty)
          .map((r) {
            final firstName = r['firstName'] ?? '';
            final lastName = r['lastName'] ?? '';
            return {
              'residentId': r['residentId'],
              'name': '$firstName $lastName',
              'house': r['house'],
              'note': r['notes'],
            };
          }).toList(),
    };

    final success = await provider.saveReport(reportData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Report Archived Successfully!', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to archive report. Please try again.', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AdminEldersProvider>();
    final total = provider.houseHeadcount;
    final present = provider.presentCount;
    final overallPercentage = total > 0 ? (present / total) * 100 : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Official Reports Summary',
                              style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                            Text(
                              'Analytics overview for ${DateTime.now().toString().split(' ')[0]}',
                              style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ATTENDANCE PER HOUSE',
                                style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 1),
                              ),
                              Row(
                                children: [
                                  _buildLegendItem('Present', isDark ? const Color(0xFF34D399) : const Color(0xFF10B981), isDark),
                                  const SizedBox(width: 12),
                                  _buildLegendItem('Absent', isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48), isDark),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 250,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _getMaxY(provider),
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 || index >= provider.houses.length) return const SizedBox();
                                        final fullHouse = provider.houses[index];
                                        String label = fullHouse.replaceAll('House of St. ', '');
                                        if(label.length > 8) label = label.substring(0, 8);
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            label,
                                            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 10),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        if (value % 5 != 0) return const SizedBox();
                                        return Text(
                                          value.toInt().toString(),
                                          style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 5,
                                  getDrawingHorizontalLine: (value) => FlLine(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), strokeWidth: 1),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _generateBarGroups(provider, isDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OVERALL PRESENCE',
                            style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 1),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 60,
                                    startDegreeOffset: -90,
                                    sections: [
                                      PieChartSectionData(
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                                        value: present.toDouble(),
                                        title: '',
                                        radius: 20,
                                      ),
                                      PieChartSectionData(
                                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F4FD),
                                        value: (total - present).toDouble(),
                                        title: '',
                                        radius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${overallPercentage.toInt()}%',
                                      style: TextStyle(fontFamily: 'Montserrat', fontSize: 36, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A), height: 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: isDark ? Colors.transparent : const Color(0xFF0F172A).withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, -4))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSaveAndDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF00A8E8) : const Color(0xFF00435C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save to Archive & PDF', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  double _getMaxY(AdminEldersProvider provider) {
    double max = 10;
    for (var house in provider.houses) {
      final hRes = provider.residents.where((r) => r['house'] == house).length;
      if (hRes > max) max = hRes.toDouble();
    }
    return max + (max * 0.2);
  }

  List<BarChartGroupData> _generateBarGroups(AdminEldersProvider provider, bool isDark) {
    return List.generate(provider.houses.length, (index) {
      final houseName = provider.houses[index];
      final hRes = provider.residents.where((r) => r['house'] == houseName);
      final present = hRes.where((r) => r['attendance'] == 'Present').length;
      final absent = hRes.where((r) => r['attendance'] == 'Not Present' || r['attendance'] == null).length;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: present.toDouble(),
            color: isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
            width: 14,
            borderRadius: BorderRadius.circular(2),
          ),
          BarChartRodData(
            toY: absent.toDouble(),
            color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
            width: 14,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    });
  }
}