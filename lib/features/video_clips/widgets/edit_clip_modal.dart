import 'package:flutter/material.dart';
import '../models/video_clip.dart';
import '../services/video_clips_service.dart';

/// "Editing a clip" is a slight misnomer worth being explicit about: the video
/// file is immutable evidence and nothing here touches it. What this edits is
/// the RECORD attached to the recording — what the event was classified as, and
/// any note a reviewer wants to leave. That is the part that is ever actually
/// wrong: the detector labels a resident lowering themselves into a chair as a
/// fall, and the nurse who watched the clip knows better.
///
/// Changing the type also moves severity server-side, so the dashboard totals
/// follow the correction instead of continuing to report the mistake.
class EditClipModal extends StatefulWidget {
  final VideoClip clip;
  final Future<void> Function(String clipId, String incidentType, String note) onSave;

  const EditClipModal({super.key, required this.clip, required this.onSave});

  @override
  State<EditClipModal> createState() => _EditClipModalState();
}

class _EditClipModalState extends State<EditClipModal> {
  static const int noteLimit = 500;

  late String _incidentType;
  late TextEditingController _noteController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Fall back to the first valid type: the dropdown asserts if its value is
    // not among its items, and an incident could carry a type that has since
    // left the enum.
    _incidentType = VideoClipsService.incidentTypes.contains(widget.clip.rawIncidentType)
        ? widget.clip.rawIncidentType
        : VideoClipsService.incidentTypes.first;
    _noteController = TextEditingController(text: widget.clip.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _incidentType != widget.clip.rawIncidentType ||
      _noteController.text != widget.clip.note;

  Future<void> _handleSave() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(widget.clip.id, _incidentType, _noteController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      debugPrint('[EditClipModal] save failed: $e');
      setState(() {
        _error = 'Could not save the change. Please try again.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A6265);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final clip = widget.clip;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Clip Details',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF00212E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${clip.dateLabel} · ${clip.timeLabel} · ${clip.cameraName}',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
              const SizedBox(height: 20),
              _label('EVENT TYPE', muted),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _incidentType,
                    dropdownColor:
                        isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    items: VideoClipsService.incidentTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _incidentType = v!),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Changing this updates the event's severity and the dashboard "
                'totals. The recording itself is not modified.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _label('NOTE (OPTIONAL)', muted),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLength: noteLimit,
                maxLines: 3,
                enabled: !_saving,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Resident sat down heavily, no fall occurred.',
                  hintStyle: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00A8E8)),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE11D48),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'This change is recorded in the audit trail with your name and '
                'the previous values.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_saving || !_dirty) ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A8E8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _saving ? 'Saving…' : 'Save Changes',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      );
}
