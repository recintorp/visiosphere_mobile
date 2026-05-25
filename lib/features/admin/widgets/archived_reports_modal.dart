import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/admin_elders_provider.dart';

class ArchivedReportsModal extends StatefulWidget {
  const ArchivedReportsModal({super.key});

  @override
  State<ArchivedReportsModal> createState() => _ArchivedReportsModalState();
}

class _ArchivedReportsModalState extends State<ArchivedReportsModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminEldersProvider>().fetchArchivedReports();
    });
  }

  Future<void> _downloadArchivePdf(dynamic report) async {
    final doc = pw.Document();

    final String reportDate = report['reportDate'] ?? 'N/A';
    final int total = report['totalResidents'] ?? 0;
    final int present = report['totalPresent'] ?? 0;
    final int absent = report['totalNotPresent'] ?? 0;

    final List<dynamic> housesSummary = report['housesSummary'] ?? [];
    final List<dynamic> absentResidents = report['absentResidents'] ?? [];
    final List<dynamic> notesSnapshot = report['notesSnapshot'] ?? [];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              title: 'VISIOSPHERE',
              textStyle: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#00435C'),
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.blueGrey200)),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Archived Facility Attendance Report', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: $reportDate', style: const pw.TextStyle(fontSize: 14)),
              ]
            ),
            pw.SizedBox(height: 24),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfSummaryStat('Total Elders', total.toString(), PdfColor.fromHex('#00A8E8')),
                  _buildPdfSummaryStat('Present', present.toString(), PdfColor.fromHex('#10B981')),
                  _buildPdfSummaryStat('Absent', absent.toString(), PdfColor.fromHex('#E11D48')),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            if (housesSummary.isNotEmpty) ...[
              pw.Text('House Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#475569'))),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#00A8E8')),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                cellPadding: const pw.EdgeInsets.all(6),
                data: <List<String>>[
                  ['House', 'Total', 'Present', 'Absent'],
                  ...housesSummary.map((h) => [
                    h['house']?.toString() ?? '',
                    h['headcount']?.toString() ?? '0',
                    h['present']?.toString() ?? '0',
                    h['notPresent']?.toString() ?? '0',
                  ]),
                ],
              ),
              pw.SizedBox(height: 24),
            ],

            if (absentResidents.isNotEmpty) ...[
              pw.Text('Absent Residents', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#E11D48'))),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellPadding: const pw.EdgeInsets.all(6),
                data: <List<String>>[
                  ['Name', 'House'],
                  ...absentResidents.map((r) => [
                    r['name']?.toString() ?? '',
                    r['house']?.toString() ?? '',
                  ]),
                ],
              ),
              pw.SizedBox(height: 24),
            ],

            if (notesSnapshot.isNotEmpty) ...[
              pw.Text('Monitoring Notes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#F59E0B'))),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellPadding: const pw.EdgeInsets.all(6),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                data: <List<String>>[
                  ['Resident', 'Note'],
                  ...notesSnapshot.map((n) => [
                    '${n['name'] ?? ''}\n(${n['house'] ?? ''})',
                    n['note']?.toString() ?? '',
                  ]),
                ],
              ),
            ],
          ];
        },
      ),
    );

    final String safeDate = reportDate.replaceAll('/', '-');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'VisioSphere_Archived_Report_$safeDate.pdf',
    );
  }

  pw.Widget _buildPdfSummaryStat(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey800)),
      ]
    );
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      String hour = date.hour > 12 ? (date.hour - 12).toString() : (date.hour == 0 ? '12' : date.hour.toString());
      String minute = date.minute.toString().padLeft(2, '0');
      String ampm = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $ampm';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                        Icon(Icons.inventory_2_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Archived Reports',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
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
            child: Consumer<AdminEldersProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingArchives) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A8E8)),
                  );
                }

                if (provider.archivedReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 64, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        const SizedBox(height: 16),
                        Text(
                          'No archived reports found.',
                          style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => provider.fetchArchivedReports(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Refresh', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                            elevation: 0,
                            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.fetchArchivedReports,
                  color: const Color(0xFF00A8E8),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: provider.archivedReports.length,
                    itemBuilder: (context, index) {
                      final report = provider.archivedReports[index];
                      return FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        delay: Duration(milliseconds: index * 50),
                        child: _buildReportCard(report, isDark),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(dynamic report, bool isDark) {
    final String date = report['reportDate'] ?? 'Unknown Date';
    final String time = report['updatedAt'] != null ? _formatTime(report['updatedAt']) : '';
    final String total = (report['totalResidents'] ?? 0).toString();
    final String present = (report['totalPresent'] ?? 0).toString();
    final String absent = (report['totalNotPresent'] ?? 0).toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                if (time.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      time,
                      style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  )
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('TOTAL', total, isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), isDark),
                _buildStatColumn('PRESENT', present, isDark ? const Color(0xFF34D399) : const Color(0xFF10B981), isDark),
                _buildStatColumn('ABSENT', absent, isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48), isDark),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          
          InkWell(
            onTap: () => _downloadArchivePdf(report),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : const Color(0xFFE1F5FE),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Download PDF',
                    style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontFamily: 'Montserrat', color: color, fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}