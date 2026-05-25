import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:quill_html_editor/quill_html_editor.dart'; 
import '../providers/admin_assessments_provider.dart';

class AssessmentBlockEditor extends StatelessWidget {
  final Map<String, dynamic> block;

  const AssessmentBlockEditor({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final type = block['type'] as String?;

    switch (type) {
      case 'text':
        return _TextBlockEditor(block: block);
      case 'checklist':
        return _ChecklistBlockEditor(block: block);
      case 'chart':
        return _ChartBlockEditor(block: block);
      case 'image':
      case 'file':
        return _FileBlockEditor(block: block);
      default:
        return const SizedBox();
    }
  }
}

class _TextBlockEditor extends StatefulWidget {
  final Map<String, dynamic> block;

  const _TextBlockEditor({required this.block});

  @override
  State<_TextBlockEditor> createState() => _TextBlockEditorState();
}

class _TextBlockEditorState extends State<_TextBlockEditor> {
  late QuillEditorController _quillController;
  bool _isEditorLoaded = false;

  @override
  void initState() {
    super.initState();
    _quillController = QuillEditorController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminAssessmentsProvider>().registerQuillController(widget.block['id'], _quillController);
    });
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: ToolBar(
            toolBarColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.all(8),
            iconSize: 20,
            iconColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            activeIconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
            controller: _quillController,
            crossAxisAlignment: WrapCrossAlignment.center,
            direction: Axis.horizontal,
            toolBarConfig: [ 
              ToolBarStyle.bold,
              ToolBarStyle.italic,
              ToolBarStyle.underline,
              ToolBarStyle.strike,
              ToolBarStyle.blockQuote,
              ToolBarStyle.align,
              ToolBarStyle.listBullet,
              ToolBarStyle.listOrdered,
              ToolBarStyle.color,
              ToolBarStyle.background,
              ToolBarStyle.clearHistory,
            ],
          ),
        ),
        
        Container(
          height: 250, 
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          child: Stack(
            children: [
              QuillHtmlEditor(
                text: widget.block['content']?.toString() ?? '',
                hintText: 'Type your detailed assessment notes here...',
                controller: _quillController,
                isEnabled: true,
                ensureVisible: false,
                minHeight: 250,
                autoFocus: false,
                textStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                hintTextAlign: TextAlign.start,
                padding: const EdgeInsets.all(16),
                hintTextPadding: const EdgeInsets.all(16),
                backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                onEditorCreated: () {
                  setState(() => _isEditorLoaded = true);
                },
              ),
              if (!_isEditorLoaded)
                Center(
                  child: CircularProgressIndicator(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistBlockEditor extends StatelessWidget {
  final Map<String, dynamic> block;

  const _ChecklistBlockEditor({required this.block});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminAssessmentsProvider>();
    final items = List<Map<String, dynamic>>.from(block['content'] ?? []);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Checkbox(
                  value: item['checked'] == true,
                  onChanged: (val) {
                    final newItems = List<Map<String, dynamic>>.from(items);
                    newItems[index]['checked'] = val;
                    provider.updateBlockContent(block['id'], newItems);
                  },
                  activeColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                  checkColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.black54),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: item['text']?.toString() ?? '',
                    onChanged: (val) {
                      final newItems = List<Map<String, dynamic>>.from(items);
                      newItems[index]['text'] = val;
                      provider.updateBlockContent(block['id'], newItems);
                    },
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Task description',
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFFE11D48)),
                  onPressed: () {
                    final newItems = List<Map<String, dynamic>>.from(items)..removeAt(index);
                    provider.updateBlockContent(block['id'], newItems);
                  },
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            final newItems = List<Map<String, dynamic>>.from(items)..add({'text': '', 'checked': false});
            provider.updateBlockContent(block['id'], newItems);
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Checklist Item', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
            side: BorderSide(color: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD), width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _ChartBlockEditor extends StatelessWidget {
  final Map<String, dynamic> block;

  const _ChartBlockEditor({required this.block});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminAssessmentsProvider>();
    final content = block['content'] as Map<String, dynamic>? ?? {};
    final dataPoints = List<Map<String, dynamic>>.from(content['dataPoints'] ?? []);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          initialValue: content['chartType']?.toString() ?? 'temperature',
          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
          onChanged: (val) {
            final newContent = Map<String, dynamic>.from(content);
            newContent['chartType'] = val;
            if (val == 'temperature') newContent['chartTitle'] = 'Temperature Tracking';
            if (val == 'vitals') newContent['chartTitle'] = 'Heart Rate Tracking';
            provider.updateBlockContent(block['id'], newContent);
          },
          items: [
            DropdownMenuItem(value: 'temperature', child: Text('Temperature (°C)', style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
            DropdownMenuItem(value: 'vitals', child: Text('Heart Rate / Vitals', style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
            DropdownMenuItem(value: 'custom', child: Text('Custom Data', style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: content['chartTitle']?.toString() ?? '',
          onChanged: (val) {
            final newContent = Map<String, dynamic>.from(content);
            newContent['chartTitle'] = val;
            provider.updateBlockContent(block['id'], newContent);
          },
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Enter Chart Title...',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))),
          ),
        ),
        
        const SizedBox(height: 16),
        Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        const SizedBox(height: 12),
        
        ...dataPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final dp = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: dp['label']?.toString() ?? '',
                    onChanged: (val) {
                      final newDp = List<Map<String, dynamic>>.from(dataPoints);
                      newDp[index]['label'] = val;
                      final newContent = Map<String, dynamic>.from(content);
                      newContent['dataPoints'] = newDp;
                      provider.updateBlockContent(block['id'], newContent);
                    },
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Label (e.g. 08:00)',
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: dp['value']?.toString() ?? '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      final newDp = List<Map<String, dynamic>>.from(dataPoints);
                      newDp[index]['value'] = double.tryParse(val) ?? 0.0;
                      final newContent = Map<String, dynamic>.from(content);
                      newContent['dataPoints'] = newDp;
                      provider.updateBlockContent(block['id'], newContent);
                    },
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Value',
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFFE11D48)),
                  onPressed: () {
                    final newDp = List<Map<String, dynamic>>.from(dataPoints)..removeAt(index);
                    final newContent = Map<String, dynamic>.from(content);
                    newContent['dataPoints'] = newDp;
                    provider.updateBlockContent(block['id'], newContent);
                  },
                ),
              ],
            ),
          );
        }),

        OutlinedButton.icon(
          onPressed: () {
            final newDp = List<Map<String, dynamic>>.from(dataPoints)..add({'label': '', 'value': 0.0});
            final newContent = Map<String, dynamic>.from(content);
            newContent['dataPoints'] = newDp;
            provider.updateBlockContent(block['id'], newContent);
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Data Point', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
            side: BorderSide(color: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD), width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _FileBlockEditor extends StatefulWidget {
  final Map<String, dynamic> block;

  const _FileBlockEditor({required this.block});

  @override
  State<_FileBlockEditor> createState() => _FileBlockEditorState();
}

class _FileBlockEditorState extends State<_FileBlockEditor> {
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final isImage = widget.block['type'] == 'image';
    
    fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      type: isImage ? fp.FileType.image : fp.FileType.any,
    );

    if (result != null && result.files.single.path != null && mounted) {
      setState(() => _isUploading = true);
      
      File file = File(result.files.single.path!);
      final provider = context.read<AdminAssessmentsProvider>();
      
      final success = await provider.uploadFileToBlock(widget.block['id'], file);
      
      if (!mounted) return;
      setState(() => _isUploading = false);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload file.'), backgroundColor: Color(0xFFE11D48)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileUrl = widget.block['fileUrl'] as String?;
    final isImage = widget.block['type'] == 'image';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (fileUrl != null) ...[
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(fileUrl, height: 150, fit: BoxFit.cover),
              )
            else
              Icon(Icons.insert_drive_file_rounded, size: 64, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
            const SizedBox(height: 16),
            Text('File uploaded successfully!', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF34D399) : const Color(0xFF10B981), fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
          ],
          
          if (_isUploading)
            CircularProgressIndicator(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))
          else
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: Icon(isImage ? Icons.image_rounded : Icons.folder_rounded),
              label: Text(fileUrl == null ? 'Select ${isImage ? 'Image' : 'File'}' : 'Replace ${isImage ? 'Image' : 'File'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF00A8E8) : const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }
}