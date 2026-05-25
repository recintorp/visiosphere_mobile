import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_assessments_provider.dart';
import 'assessment_block_editors.dart';

class TagInput extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onChange;
  final List<String> suggestions;
  final bool isDark;

  const TagInput({
    super.key,
    required this.tags,
    required this.onChange,
    required this.suggestions,
    required this.isDark,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !widget.tags.contains(trimmed)) {
      widget.onChange([...widget.tags, trimmed]);
    }
    _controller.clear();
    setState(() {
      _showSuggestions = false;
    });
  }

  void _removeTag(String tag) {
    widget.onChange(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuggestions = widget.suggestions
        .where((s) => !widget.tags.contains(s) && s.toLowerCase().contains(_controller.text.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: Border.all(color: _focusNode.hasFocus ? const Color(0xFF00A8E8) : (widget.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...widget.tags.map((tag) => Container(
                padding: const EdgeInsets.only(left: 10.0, right: 4.0, top: 4.0, bottom: 4.0),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    InkWell(
                      onTap: () => _removeTag(tag),
                      child: Icon(Icons.close, size: 16.0, color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              )),
              IntrinsicWidth(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 14.0, color: widget.isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: widget.tags.isEmpty ? '+ Add tags (e.g. Fall Incident, Vitals)...' : '',
                    hintStyle: TextStyle(color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (text) {
                    setState(() {});
                    if (text.endsWith(',') || text.endsWith(' ')) {
                      _addTag(text.substring(0, text.length - 1));
                    }
                  },
                  onSubmitted: _addTag,
                ),
              ),
            ],
          ),
        ),
        if (_showSuggestions && filteredSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4.0),
            constraints: const BoxConstraints(maxHeight: 150.0),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border.all(color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4.0, offset: const Offset(0, 2)),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = filteredSuggestions[index];
                return InkWell(
                  onTap: () => _addTag(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class AssessmentBuilderSheet extends StatefulWidget {
  final String residentId;
  final String residentName;
  final String authorId;
  final String authorName;

  const AssessmentBuilderSheet({
    super.key,
    required this.residentId,
    required this.residentName,
    required this.authorId,
    required this.authorName,
  });

  @override
  State<AssessmentBuilderSheet> createState() => _AssessmentBuilderSheetState();
}

class _AssessmentBuilderSheetState extends State<AssessmentBuilderSheet> {
  late TextEditingController _titleController;
  bool _isSubmitting = false;
  final List<String> _predefinedTags = [
    'Routine Vitals',
    'Fall Incident',
    'Agitation/Pacing',
    'Medication Adjustment',
    'Dietary Note',
    'General Observation',
    'Physician Visit'
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<AdminAssessmentsProvider>();
    _titleController = TextEditingController(text: provider.reportTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final provider = context.read<AdminAssessmentsProvider>();
    
    await provider.syncHtmlContentBeforeSave(); 

    if (!mounted) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an official report title.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)),
      );
      return;
    }

    if (provider.blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one module to the report.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    provider.setReportTitle(_titleController.text.trim());

    final success = await provider.submitReport(
      residentId: widget.residentId,
      residentName: widget.residentName,
      authorId: widget.authorId,
      authorName: widget.authorName,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.editingId != null ? 'Report updated successfully.' : 'Report submitted successfully.', style: const TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save report.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)),
      );
    }
  }

  Widget _buildBlockWrapper(Map<String, dynamic> block, AdminAssessmentsProvider provider, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 12.0, offset: const Offset(0, 6.0)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${block['type']} Module'.toUpperCase(),
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 12.0, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), letterSpacing: 1.2),
                ),
                InkWell(
                  onTap: () => provider.removeBlock(block['id']),
                  borderRadius: BorderRadius.circular(20.0),
                  child: Icon(Icons.close_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 22.0),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(block['type'] == 'text' ? 0.0 : 20.0),
            child: AssessmentBlockEditor(block: block),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAssessmentsProvider>();
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF020617) : const Color(0xFFF1F5F9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4.0)),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 20.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 4.0, offset: Offset(0, 2.0)),
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 22.0, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Document Title...',
                    hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
                TagInput(
                  tags: provider.reportTags,
                  onChange: (newTags) => provider.setReportTags(newTags),
                  suggestions: _predefinedTags,
                  isDark: isDark,
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.resetBuilder();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(height: 20.0, width: 20.0, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                            : Text(
                                provider.editingId != null ? 'Update Record' : 'Save & Publish',
                                style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 14.0),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 40.0,
              ),
              child: Column(
                children: [
                  if (provider.blocks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 80.0),
                      child: Column(
                        children: [
                          Icon(Icons.post_add_rounded, size: 64.0, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1).withValues(alpha: 0.5)),
                          const SizedBox(height: 16.0),
                          Text('Blank Document', style: TextStyle(fontFamily: 'Montserrat', fontSize: 18.0, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569))),
                          const SizedBox(height: 8.0),
                          Text('Select a specialized module below to begin.', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), fontSize: 13.0)),
                        ],
                      ),
                    )
                  else
                    ...provider.blocks.map((block) => _buildBlockWrapper(block, provider, isDark)),

                  const SizedBox(height: 24.0),
                  const Text('APPEND MODULE', style: TextStyle(fontFamily: 'Montserrat', fontSize: 11.0, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
                  const SizedBox(height: 16.0),
                  
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildAddModuleBtn('text', 'Notes', Icons.text_snippet_rounded, provider, isDark),
                      _buildAddModuleBtn('checklist', 'Checklist', Icons.checklist_rounded, provider, isDark),
                      _buildAddModuleBtn('chart', 'Vitals Chart', Icons.show_chart_rounded, provider, isDark),
                      _buildAddModuleBtn('image', 'Image', Icons.image_rounded, provider, isDark),
                      _buildAddModuleBtn('file', 'File', Icons.attach_file_rounded, provider, isDark),
                    ],
                  ),
                  if (isKeyboardOpen) const SizedBox(height: 150.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddModuleBtn(String type, String label, IconData icon, AdminAssessmentsProvider provider, bool isDark) {
    return ElevatedButton.icon(
      onPressed: () => provider.addBlock(type),
      icon: Icon(icon, size: 16.0),
      label: Text(label, style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 12.0)),
      style: ElevatedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      ),
    );
  }
}