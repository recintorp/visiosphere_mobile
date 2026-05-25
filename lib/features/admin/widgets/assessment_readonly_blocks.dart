import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart'; // ADDED IMPORT

class AssessmentReadonlyBlock extends StatelessWidget {
  final Map<String, dynamic> block;

  const AssessmentReadonlyBlock({super.key, required this.block});

  Future<void> _launchUrl(String? urlStr) async {
    if (urlStr == null || urlStr.isEmpty) return;
    final Uri url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = block['type'] as String?;
    final content = block['content'];
    final fileUrl = block['fileUrl'] as String?;

    switch (type) {
      case 'text':
        // REPLACED standard Text widget with Html widget to render React-Quill output
        return Html(
          data: content?.toString() ?? '',
          style: {
            "body": Style(
              fontFamily: 'Montserrat',
              fontSize: FontSize(13.0),
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              lineHeight: LineHeight(1.6),
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
            ),
            "h1": Style(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              margin: Margins.only(top: 8.0, bottom: 8.0),
            ),
            "h2": Style(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              margin: Margins.only(top: 8.0, bottom: 8.0),
            ),
            "h3": Style(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              margin: Margins.only(top: 8.0, bottom: 8.0),
            ),
            "p": Style(
              margin: Margins.only(bottom: 8.0),
            ),
            "ul": Style(
              margin: Margins.only(left: 0.0),
              padding: HtmlPaddings.only(left: 20.0),
            ),
            "ol": Style(
              margin: Margins.only(left: 0.0),
              padding: HtmlPaddings.only(left: 20.0),
            ),
          },
        );

      case 'checklist':
        if (content is! List) return const SizedBox();
        return Column(
          children: content.map((item) {
            final isChecked = item['checked'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isChecked 
                      ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)) 
                      : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['text']?.toString() ?? '',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: isChecked 
                          ? (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)) 
                          : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 'chart':
        if (content is! Map<String, dynamic>) return const SizedBox();
        return _buildChartPreview(content, isDark);

      case 'image':
        if (fileUrl == null || fileUrl.isEmpty) return const SizedBox();
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              fileUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                child: Column(
                  children: [
                    Icon(Icons.broken_image_rounded, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), size: 48),
                    const SizedBox(height: 8),
                    Text('Image failed to load', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ),
        );

      case 'file':
        if (fileUrl == null || fileUrl.isEmpty) return const SizedBox();
        return OutlinedButton.icon(
          onPressed: () => _launchUrl(fileUrl),
          icon: const Icon(Icons.download_rounded, size: 20),
          label: const Text('Download Attached File', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
            backgroundColor: isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : const Color(0xFFF0F9FF),
            side: BorderSide(color: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildChartPreview(Map<String, dynamic> content, bool isDark) {
    final dataPoints = content['dataPoints'] as List<dynamic>? ?? [];
    if (dataPoints.isEmpty) return const SizedBox();

    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < dataPoints.length; i++) {
      final val = (dataPoints[i]['value'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), val));
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }

    if (minY == double.infinity) minY = 0;
    if (maxY == double.negativeInfinity) maxY = 10;
    
    minY = minY - (minY * 0.1);
    maxY = maxY + (maxY * 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content['chartTitle']?.toString() ?? 'Chart',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.only(right: 16, left: 0, top: 16, bottom: 0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 4 == 0 ? 1 : (maxY - minY) / 4,
                getDrawingHorizontalLine: (value) => FlLine(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), strokeWidth: 1, dashArray: [5, 5]),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < dataPoints.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            dataPoints[value.toInt()]['label']?.toString() ?? '',
                            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10, fontFamily: 'Montserrat'),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (maxY - minY) / 4 == 0 ? 1 : (maxY - minY) / 4,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10, fontFamily: 'Montserrat'),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (dataPoints.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                        strokeWidth: 2,
                        strokeColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.1) : const Color(0xFF00A8E8).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}