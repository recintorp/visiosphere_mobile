import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/guardian_provider.dart';
import '../../../core/constants/api_constants.dart';

class GuardianJournalWidget extends StatefulWidget {
  final bool hasElder;
  final String elderName;
  final DateTime selectedDate;
  final Map<String, dynamic>? assessment;

  const GuardianJournalWidget({
    super.key, 
    required this.hasElder,
    required this.elderName,
    required this.selectedDate,
    required this.assessment,
  });

  @override
  State<GuardianJournalWidget> createState() => _GuardianJournalWidgetState();
}

class _GuardianJournalWidgetState extends State<GuardianJournalWidget> {
  int? _selectedEmojiIndex;
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;
  bool _isJournalExpanded = true;

  final List<Map<String, dynamic>> _emojis = [
    {'emoji': '❤️', 'label': 'Love', 'key': 'heart'},
    {'emoji': '👍', 'label': 'Thanks', 'key': 'thumbsUp'},
    {'emoji': '😊', 'label': 'Happy', 'key': 'acknowledged'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeEmojiState();
  }

  void _initializeEmojiState() {
    if (widget.assessment != null && widget.assessment!['reactions'] != null) {
      for (int i = 0; i < _emojis.length; i++) {
        if (widget.assessment!['reactions'][_emojis[i]['key']] == 1 || 
            widget.assessment!['reactions'][_emojis[i]['key']] == true) {
          _selectedEmojiIndex = i;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleJournal() {
    setState(() {
      _isJournalExpanded = !_isJournalExpanded;
    });
  }

  void _openPdfPreview() {
    final String formattedDate = '${widget.selectedDate.month.toString().padLeft(2, '0')}/${widget.selectedDate.day.toString().padLeft(2, '0')}/${widget.selectedDate.year}';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalPdfPreviewScreen(
          elderName: widget.elderName,
          date: formattedDate,
          assessment: widget.assessment!,
        ),
      ),
    );
  }

  Future<void> _handleReactionTap(int index) async {
    final newIndex = _selectedEmojiIndex == index ? null : index;
    setState(() => _selectedEmojiIndex = newIndex);
    
    final reactionKey = _emojis[index]['key'];
    final isActive = newIndex != null;
    
    final success = await context.read<GuardianProvider>().sendReaction(
      widget.assessment!['_id'], 
      reactionKey, 
      isActive
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Reaction added' : 'Reaction removed'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleSendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isSendingComment = true);
    
    final success = await context.read<GuardianProvider>().sendComment(
      widget.assessment!['_id'], 
      _commentController.text
    );
    
    if (mounted) {
      setState(() => _isSendingComment = false);
      if (success) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message successfully sent to care team'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final String formattedDate = '${widget.selectedDate.month.toString().padLeft(2, '0')}/${widget.selectedDate.day.toString().padLeft(2, '0')}/${widget.selectedDate.year}';
    final bool hasReportData = widget.assessment != null;
    final List<dynamic> tags = widget.assessment?['tags'] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.book_rounded, color: theme.colorScheme.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Daily Journal',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -0.3),
                        ),
                      ],
                    ),
                    if (hasReportData)
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)),
                        onPressed: _openPdfPreview,
                        tooltip: 'Preview & Download PDF',
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildJournalHeaderItem(Icons.elderly_rounded, 'Elder', widget.elderName, theme),
                _buildJournalHeaderItem(Icons.calendar_today_rounded, 'Date', formattedDate, theme),
                if (hasReportData) ...[
                  _buildJournalHeaderItem(Icons.medical_services_rounded, 'Nurse', widget.assessment!['authorName'] ?? 'Unknown', theme),
                  const SizedBox(height: 16),
                  
                  GestureDetector(
                    onTap: _toggleJournal,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.assessment!['title'] ?? 'Daily Assessment',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: theme.colorScheme.primary, letterSpacing: -0.3),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _isJournalExpanded ? 0 : 0.5,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                                border: Border.all(color: isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag.toString(),
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                if (!hasReportData) ...[
                  const SizedBox(height: 20),
                  _buildEmptyState(theme, isDark),
                ] else ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.fastOutSlowIn,
                    alignment: Alignment.topCenter,
                    child: _isJournalExpanded
                        ? Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: _renderBlocks(widget.assessment!['blocks'], theme),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  
                  const SizedBox(height: 32),
                  Text(
                    'Leave a reaction',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_emojis.length, (index) {
                      bool isSelected = _selectedEmojiIndex == index;
                      return GestureDetector(
                        onTap: () => _handleReactionTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.15) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.5) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(_emojis[index]['emoji'], style: const TextStyle(fontSize: 28)),
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 32),
                  Text(
                    'Message to the Care Team',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    minLines: 2,
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Type your message or follow-up question here...',
                      hintStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSendingComment ? null : _handleSendComment,
                      icon: _isSendingComment 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_isSendingComment ? 'Sending...' : 'Send Message', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  
                  if (widget.assessment!['comments'] != null && widget.assessment!['comments'].isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 24),
                    Text(
                      'Communication History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: widget.assessment!['comments'].length,
                        itemBuilder: (context, index) {
                          final List commentsList = widget.assessment!['comments'] ?? [];
                          final reversedComments = commentsList.reversed.toList();
                          final comment = reversedComments[index];
                          final isGuardian = comment['senderRole'] == 'Guardian';
                          
                          String formattedTime = '';
                          if (comment['createdAt'] != null || comment['timestamp'] != null) {
                            try {
                              DateTime dt = DateTime.parse(comment['createdAt'] ?? comment['timestamp']).toLocal();
                              int hour = dt.hour;
                              final minute = dt.minute.toString().padLeft(2, '0');
                              final ampm = hour >= 12 ? 'PM' : 'AM';
                              hour = hour % 12;
                              if (hour == 0) hour = 12;
                              formattedTime = '$hour:$minute $ampm';
                            } catch (_) {}
                          }
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isGuardian 
                                  ? theme.colorScheme.primary.withValues(alpha: 0.05) 
                                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isGuardian ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: isGuardian ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                              border: Border.all(
                                color: isGuardian 
                                    ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment['senderName'] ?? 'User',
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: theme.colorScheme.onSurface),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isGuardian ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            comment['senderRole'] ?? '',
                                            style: TextStyle(
                                              fontSize: 10, 
                                              fontWeight: FontWeight.w700,
                                              color: isGuardian 
                                                  ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)) 
                                                  : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (formattedTime.isNotEmpty)
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  comment['text'] ?? '',
                                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.4, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ]
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_late_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            'No Report Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There is no daily assessment filed for this date yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalHeaderItem(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderBlocks(List<dynamic>? blocks, ThemeData theme) {
    if (blocks == null || blocks.isEmpty) {
      return Text('No detailed notes provided.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map<Widget>((block) {
        final type = block['type'];
        final content = block['content'];
        final fileUrl = block['fileUrl'];

        if (type == 'text') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              content?.toString() ?? '',
              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurfaceVariant, height: 1.5, fontWeight: FontWeight.w500),
            ),
          );
        }

        if (type == 'checklist' && content is List) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.map<Widget>((item) {
                final bool isChecked = item['checked'] == true;
                final String text = item['text']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 20,
                        color: isChecked ? const Color(0xFF10B981) : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isChecked ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                            decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }

        if (type == 'image' && fileUrl != null) {
          final fullUrl = fileUrl.startsWith('http') ? fileUrl : '${ApiConstants.baseUrl.replaceAll('/api', '')}$fileUrl';
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                fullUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Column(
                      children: [
                        Icon(Icons.broken_image_rounded, color: Color(0xFFEF4444)),
                        SizedBox(height: 8),
                        Text('Image failed to load', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ]
                    )
                  ),
              ),
            ),
          );
        }

        if (type == 'chart') {
          final title = content?['chartTitle'] ?? 'Data Chart';
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2))
              ),
              child: Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                ]
              )
            )
          );
        }

        return const SizedBox.shrink();
      }).toList(),
    );
  }
}

class JournalPdfPreviewScreen extends StatelessWidget {
  final String elderName;
  final String date;
  final Map<String, dynamic> assessment;

  const JournalPdfPreviewScreen({
    super.key,
    required this.elderName,
    required this.date,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Preview', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    final blocks = assessment['blocks'] as List<dynamic>? ?? [];
    final tags = assessment['tags'] as List<dynamic>? ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('VisioSphere', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.Text('Daily Journal Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.blue800),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Elder: $elderName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 4),
                  pw.Text('Nurse / Author: ${assessment['authorName'] ?? 'Unknown'}', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            pw.Text(
              assessment['title'] ?? 'Daily Assessment',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            
            if (tags.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((tag) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.blue200),
                  ),
                  child: pw.Text(
                    tag.toString(),
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.blue800, fontWeight: pw.FontWeight.bold),
                  ),
                )).toList(),
              ),
            ],
            
            pw.SizedBox(height: 16),

            ...blocks.map((block) {
              final type = block['type'];
              final content = block['content'];

              if (type == 'text') {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Text(content?.toString() ?? '', style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5)),
                );
              }

              if (type == 'checklist' && content is List) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: content.map((item) {
                      final bool isChecked = item['checked'] == true;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 12,
                              height: 12,
                              margin: const pw.EdgeInsets.only(top: 2, right: 8),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey700),
                                color: isChecked ? PdfColors.blueGrey800 : PdfColors.white,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                item['text']?.toString() ?? '',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: isChecked ? PdfColors.grey600 : PdfColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
              return pw.SizedBox();
            }),
          ];
        },
      ),
    );

    return pdf.save();
  }
}