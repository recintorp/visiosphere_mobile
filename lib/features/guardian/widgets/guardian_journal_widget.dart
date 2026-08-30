import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/guardian_provider.dart';
import '../../admin/widgets/assessment_readonly_blocks.dart';

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

  /// Report blocks are rendered by [AssessmentReadonlyBlock] — the same widget
  /// the admin and nurse views use.
  ///
  /// This method used to be a second, independent copy of that rendering, and
  /// it had drifted: report text is HTML from the Quill editor and was being
  /// pushed through a plain Text widget (so guardians saw literal <p> and
  /// &nbsp;), and there was no branch for `file` blocks at all, so an
  /// attachment simply rendered as nothing. Both were already solved in the
  /// shared widget. One renderer means a fix in one place reaches every reader
  /// of a report, which is the point.
  Widget _renderBlocks(List<dynamic>? blocks, ThemeData theme) {
    if (blocks == null || blocks.isEmpty) {
      return Text('No detailed notes provided.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map<Widget>((block) {
        if (block is! Map) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: AssessmentReadonlyBlock(
            block: Map<String, dynamic>.from(block),
          ),
        );
      }).toList(),
    );
  }
}

/// Flatten the Quill editor's HTML into plain text for the PDF.
///
/// The on-screen report renders this HTML properly (flutter_html, via
/// AssessmentReadonlyBlock). The `pdf` package has no HTML renderer, so
/// pushing the raw string into pw.Text printed literal `<p>` and `&nbsp;` in
/// the guardian's downloaded copy. This keeps the text and the paragraph
/// breaks and drops everything else — enough for a printed record, and
/// honest about what it is rather than pretending to lay out markup.
String htmlToPlainText(String? html) {
  if (html == null || html.trim().isEmpty) return '';
  var out = html;

  // Block-level tags become line breaks before any tag is stripped, otherwise
  // every paragraph would run into the next one.
  out = out.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  out = out.replaceAll(RegExp(r'</(p|div|li|h[1-6]|tr)>', caseSensitive: false), '\n');
  out = out.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');
  out = out.replaceAll(RegExp(r'<[^>]+>'), '');

  // The handful of entities Quill actually emits. Ampersand goes last, or it
  // would re-decode the others' escapes.
  const entities = {
    '&nbsp;': ' ', '&lt;': '<', '&gt;': '>', '&quot;': '"',
    '&#39;': "'", '&apos;': "'", '&amp;': '&',
  };
  entities.forEach((k, v) => out = out.replaceAll(k, v));

  // Numeric entities, then collapse the blank lines the tag-stripping leaves.
  out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m[1]!);
    return code == null ? m[0]! : String.fromCharCode(code);
  });
  out = out.replaceAll(RegExp(r'[ \t]+'), ' ');
  out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return out.trim();
}

/// A readable name for an attachment.
///
/// The API sends `fileName` (the stored name) alongside the signed `fileUrl`.
/// Falling back to the URL's last path segment keeps S3-era attachments, which
/// have no `fileName`, from printing as a blank line.
String attachmentLabel(Map block) {
  final name = block['fileName'];
  if (name is String && name.trim().isNotEmpty) return name.trim();

  final url = block['fileUrl'];
  if (url is String && url.isNotEmpty) {
    try {
      final segments = Uri.parse(url).pathSegments;
      if (segments.isNotEmpty) return Uri.decodeComponent(segments.last);
    } catch (_) {
      // fall through
    }
  }
  return 'Attached file';
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

    // Images have to be resolved BEFORE the page is built: pw.Image needs real
    // bytes and MultiPage.build is synchronous, which is why the PDF silently
    // dropped every attachment. The URL the API hands back is signed and
    // short-lived, so it is fetched now and used immediately.
    //
    // One unreachable image must not cost the guardian the whole report, so a
    // failure is recorded as a missing entry and noted in the page instead.
    final Map<int, pw.ImageProvider> blockImages = {};
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block is! Map) continue;
      if (block['type'] != 'image') continue;
      final url = block['fileUrl'];
      if (url is! String || !url.startsWith('http')) continue;
      try {
        blockImages[i] = await networkImage(url);
      } catch (_) {
        // left absent on purpose — rendered as a placeholder line below
      }
    }

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

            ...blocks.asMap().entries.map((entry) {
              final index = entry.key;
              final block = entry.value;
              final type = block['type'];
              final content = block['content'];

              if (type == 'text') {
                // Flattened, not raw: the editor stores HTML and pw.Text would
                // print the tags. See htmlToPlainText above.
                final text = htmlToPlainText(content?.toString());
                if (text.isEmpty) return pw.SizedBox();
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Text(text, style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5)),
                );
              }

              if (type == 'image') {
                final image = blockImages[index];
                if (image == null) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Text(
                        'Attached image could not be loaded.',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ),
                  );
                }
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Center(
                    child: pw.ConstrainedBox(
                      // Capped so a tall photo cannot push everything after it
                      // onto later pages.
                      constraints: const pw.BoxConstraints(maxHeight: 320),
                      child: pw.Image(image, fit: pw.BoxFit.contain),
                    ),
                  ),
                );
              }

              if (type == 'file') {
                // A PDF cannot open an attachment, so the honest thing is to
                // name it. Rendering nothing — which is what happened before —
                // hid from the reader that the report had an attachment at all.
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue200),
                      color: PdfColors.blue50,
                    ),
                    child: pw.Text(
                      'Attached file: ${attachmentLabel(block)}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue800),
                    ),
                  ),
                );
              }

              if (type == 'chart' && content is Map) {
                // The values, not a picture of them. A printed record of a
                // resident's vitals is read for the numbers, and a table cannot
                // be misread the way an unlabelled sparkline can.
                final title = content['chartTitle']?.toString() ?? 'Data Chart';
                final points = content['dataPoints'] as List<dynamic>? ?? [];
                if (points.isEmpty) return pw.SizedBox();
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 6),
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                            children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Reading', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Value', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                            ],
                          ),
                          ...points.map((pt) {
                            final label = (pt is Map ? pt['label'] : null)?.toString() ?? '';
                            final value = (pt is Map ? pt['value'] : null)?.toString() ?? '';
                            return pw.TableRow(children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
                            ]);
                          }),
                        ],
                      ),
                    ],
                  ),
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