import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_assessments_provider.dart';
import 'assessment_readonly_blocks.dart'; 

class AssessmentHistoryCard extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final String residentId;
  final bool isNurseView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AssessmentHistoryCard({
    super.key,
    required this.assessment,
    required this.residentId,
    required this.isNurseView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AssessmentHistoryCard> createState() => _AssessmentHistoryCardState();
}

class _AssessmentHistoryCardState extends State<AssessmentHistoryCard> {
  bool _isExpanded = false;
  final TextEditingController _commentCtrl = TextEditingController();
  bool _isSending = false;

  final Map<String, String> _emojiMap = {
    'heart': '❤️',
    'thumbsUp': '👍',
    'acknowledged': '😊',
  };

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      String hour = date.hour > 12 ? '${date.hour - 12}' : '${date.hour}';
      if (hour == '0') hour = '12';
      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.month}/${date.day}/${date.year} $hour:$minute $ampm';
    } catch (_) {
      return dateStr;
    }
  }

  void _handleSendComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    final provider = context.read<AdminAssessmentsProvider>();
    final success = await provider.sendComment(
      assessmentId: widget.assessment['_id'],
      residentId: widget.residentId,
      senderId: widget.isNurseView ? 'N-001' : 'A-001', 
      senderName: widget.isNurseView ? 'Duty Nurse' : 'Facility Admin',
      senderRole: widget.isNurseView ? 'Nurse' : 'Facility Administrator',
      text: _commentCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      _commentCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply sent successfully.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFF10B981)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reply.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)),
      );
    }
  }

  Widget _buildCollapsedInteractions(Map<String, dynamic> reactions, List<dynamic> comments, bool isDark) {
    final hasReactions = reactions.values.any((v) => v == true || (v is int && v > 0));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasReactions)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: reactions.entries.where((e) => (e.value == true || (e.value is int && (e.value as int) > 0)) && _emojiMap.containsKey(e.key)).map((e) {
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : const Color(0xFFF0F9FF),
                    border: Border.all(color: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_emojiMap[e.key]!, style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
            ),
          ),
        if (comments.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: '${comments.last['senderName']} ',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          children: [
                            TextSpan(
                              text: '(${comments.last['senderRole']})',
                              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.normal, fontSize: 10),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDateTime(comments.last['createdAt'] ?? comments.last['date']),
                      style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '"${comments.last['text']}"',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedContent(List<dynamic> blocks, Map<String, dynamic> reactions, List<dynamic> comments, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
        
        // Report Content Blocks
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report Content', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 16),
              if (blocks.isEmpty)
                Text('No data blocks were added.', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontStyle: FontStyle.italic, fontSize: 13))
              else
                ...blocks.map((block) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (block['type'] ?? 'Unknown').toString().toUpperCase(),
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        AssessmentReadonlyBlock(block: block as Map<String, dynamic>),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Reactions
        Text('Reactions', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Row(
          children: reactions.values.any((v) => v == true || (v is int && v > 0))
              ? reactions.entries.where((e) => (e.value == true || (e.value is int && (e.value as int) > 0)) && _emojiMap.containsKey(e.key)).map((e) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : const Color(0xFFF0F9FF),
                      border: Border.all(color: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(_emojiMap[e.key]!, style: const TextStyle(fontSize: 20)),
                  );
                }).toList()
              : [Text('No guardian reactions yet.', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13))],
        ),

        const SizedBox(height: 24),

        // Communication Log
        Text('Communication Log', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        const SizedBox(height: 12),
        if (comments.isEmpty)
          Text('No comments recorded.', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13))
        else
          ...comments.map((c) {
            final isGuardian = c['senderRole'] == 'Guardian';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isGuardian 
                  ? (isDark ? const Color(0xFF082F49).withValues(alpha: 0.3) : const Color(0xFFEFF6FF)) 
                  : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4)),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: isGuardian ? const Color(0xFF3B82F6) : const Color(0xFF10B981), width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: '${c['senderName']} ',
                            style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            children: [
                              TextSpan(
                                text: '(${c['senderRole']})',
                                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.normal, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        _formatDateTime(c['createdAt'] ?? c['date']),
                        style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c['text'] ?? '',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155), height: 1.5),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 16),
        
        // Reply Input
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Type an official reply...',
                  hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isSending ? null : _handleSendComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF00A8E8) : const Color(0xFF00A8E8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSending 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Reply', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        const SizedBox(height: 16),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: widget.onEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Edit Report Data', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            if (!widget.isNurseView) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.onDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Delete Permanently', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.assessment['title'] ?? 'Daily Assessment Update';
    final date = _formatDate(widget.assessment['createdAt'] ?? widget.assessment['date']);
    final author = widget.assessment['authorName'] ?? 'Unknown Author';
    final blocks = widget.assessment['blocks'] as List<dynamic>? ?? [];
    final comments = widget.assessment['comments'] as List<dynamic>? ?? [];
    final reactions = widget.assessment['reactions'] as Map<String, dynamic>? ?? {};
    final tags = widget.assessment['tags'] as List<dynamic>? ?? [];
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: _isExpanded ? (isDark ? 0 : 8) : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isExpanded ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: _isExpanded ? 2 : 1,
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shadowColor: isDark ? Colors.transparent : const Color(0xFF0F172A).withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A), height: 1.3),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : const Color(0xFFE1F5FE), borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                date,
                                style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                            ...tags.map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFF1F5F9),
                                    border: Border.all(color: isDark ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag.toString(),
                                    style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      _isExpanded ? 'Close ▴' : 'View ▾',
                      style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Meta Row
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text('By: $author', style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  Text('Blocks: ${blocks.length}', style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  Text('Comments: ${comments.length}', style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),

              if (!_isExpanded)
                _buildCollapsedInteractions(reactions, comments, isDark)
              else
                _buildExpandedContent(blocks, reactions, comments, isDark),
            ],
          ),
        ),
      ),
    );
  }
}