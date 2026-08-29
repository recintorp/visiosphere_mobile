import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/video_clip.dart';

/// Handles one clip or many.
///
/// A plain confirm would be cheaper, but this deletes CCTV footage of detected
/// falls from a care facility, and the dialog is explicit about the two things
/// people get wrong about that:
///
///   1. It is PERMANENT. The files are removed from the recorder's disk; there
///      is no soft-delete and no undo.
///   2. The INCIDENTS SURVIVE. Deleting footage does not remove the falls from
///      the reports. Staff who assume otherwise might delete recordings
///      expecting the events to disappear from the statistics — they will not,
///      and that is deliberate.
class DeleteClipDialog extends StatefulWidget {
  final List<VideoClip> clips;
  final Future<void> Function(
    List<String> ids, {
    CancelToken? cancelToken,
    void Function(int current, int total)? onProgress,
  }) onConfirm;

  const DeleteClipDialog({
    super.key,
    required this.clips,
    required this.onConfirm,
  });

  @override
  State<DeleteClipDialog> createState() => _DeleteClipDialogState();
}

class _DeleteClipDialogState extends State<DeleteClipDialog> {
  bool _deleting = false;
  int? _progressCurrent;
  int? _progressTotal;
  String? _error;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    // If the dialog closes mid-delete, cancel rather than leaving a request
    // pending against a widget that no longer exists.
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final token = CancelToken();
    _cancelToken = token;
    setState(() {
      _deleting = true;
      _progressCurrent = null;
      _progressTotal = null;
      _error = null;
    });

    try {
      await widget.onConfirm(
        widget.clips.map((c) => c.id).toList(),
        cancelToken: token,
        onProgress: (current, total) {
          if (!mounted || total <= 1) return;
          setState(() {
            _progressCurrent = current;
            _progressTotal = total;
          });
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (token.isCancelled) return; // user backed out; nothing to report
      if (!mounted) return;
      debugPrint('[DeleteClipDialog] delete failed: $e');
      setState(() {
        _error = e is Exception && e.toString().isNotEmpty
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Could not delete. The recorder may be offline — nothing was removed.';
        _deleting = false;
        _progressCurrent = null;
        _progressTotal = null;
      });
    }
  }

  // Cancel stays live DURING the delete, on purpose. Disabling it while
  // deleting means a stalled request — an unreachable recorder, a cold backend
  // — leaves the dialog spinning with every control dead and no way out but
  // killing the app. A destructive operation is exactly the wrong place to trap
  // someone. Cancelling cannot un-delete files already removed, so the wording
  // below says so.
  void _handleCancel() {
    _cancelToken?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A6265);
    final list = widget.clips;
    final many = list.length > 1;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: Color(0xFFE11D48)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      many
                          ? 'Delete ${list.length} recordings?'
                          : 'Delete this recording?',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF00212E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 132),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: list
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                many
                                    ? '${c.eventType} · ${c.dateLabel} · ${c.timeLabel}'
                                    : '${c.eventType} · ${c.dateLabel} · ${c.timeLabel} · ${c.cameraName}',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: muted,
                                  height: 1.5,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${many ? 'These video files are' : 'The video file is'} '
                'permanently removed from the recorder. This cannot be undone.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${many ? 'The events themselves stay' : 'The event itself stays'} '
                'in the records and ${many ? 'continue' : 'continues'} to count '
                'in reports — only the footage is deleted. Your name and the '
                'time are written to the audit trail.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: muted,
                  height: 1.5,
                ),
              ),
              if (_deleting) ...[
                const SizedBox(height: 10),
                Text(
                  'Stopping will not restore recordings already deleted.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _handleCancel,
                    child: Text(
                      _deleting ? 'Stop' : 'Cancel',
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
                    onPressed: _deleting ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _deleting
                          ? (_progressTotal != null
                              ? 'Deleting $_progressCurrent of $_progressTotal…'
                              : 'Deleting…')
                          : many
                              ? 'Delete ${list.length} Recordings'
                              : 'Delete Recording',
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
}
