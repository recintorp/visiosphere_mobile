import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_clip.dart';
import '../services/video_clips_service.dart';

/// Playback for one clip.
///
/// The playable URL is deliberately NOT carried on [VideoClip] — it is resolved
/// here, on open, via getClipVideoUrl(), so a signed token is minted only for a
/// clip someone actually opens rather than for every card in a list being
/// browsed.
///
/// [onDuration] hands the real duration back once the player reads it, so the
/// card's badge can populate. There is no backend field for it.
class VideoPlayerModal extends StatefulWidget {
  final VideoClip clip;
  final ValueChanged<String>? onDuration;

  const VideoPlayerModal({super.key, required this.clip, this.onDuration});

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  VideoPlayerController? _controller;
  bool _urlLoading = true;
  String? _urlError;
  String? _playbackError;
  String? _duration;

  @override
  void initState() {
    super.initState();
    _resolveAndPlay();
  }

  static String _formatDuration(Duration d) {
    final total = d.inSeconds;
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _resolveAndPlay() async {
    try {
      final url = await VideoClipsService().getClipVideoUrl(widget.clip.id);
      if (!mounted) return;

      if (url == null) {
        // Not an error — the incident exists but its clip isn't ready yet
        // (ai_core's cctv_alert fires before cctv_alert_clip, so there is a real
        // window where this is expected) or the file went missing on disk. Say
        // so plainly rather than showing a broken player.
        setState(() {
          _urlError = 'This clip is not available yet.';
          _urlLoading = false;
        });
        return;
      }

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.play();

      final duration = _formatDuration(controller.value.duration);
      widget.onDuration?.call(duration);

      setState(() {
        _controller = controller;
        _duration = duration;
        _urlLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[VideoPlayerModal] playback failed: $e');
      setState(() {
        // Two very different failures land here and the wording has to cover
        // both without guessing: the file could not be fetched (recorder
        // stopped, link expired) or it downloaded but could not be decoded
        // (recorded as mp4v without the H.264 transcode step).
        _playbackError =
            'This clip could not be played. The clip server on the mini PC may '
            'be stopped, the playback link may have expired — close and reopen '
            'to request a fresh one — or the recording needs the H.264 '
            'transcode step.';
        _urlLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clip = widget.clip;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clip.eventType == 'Inactivity'
                            ? clip.eventType
                            : '${clip.eventType} Detected',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF00212E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${clip.dateLabel} · ${clip.timeLabel} · ${clip.cameraName}'
                        '${_duration != null ? ' · $_duration' : ''}',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF5A6265),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF5A6265),
                  tooltip: 'Close video player',
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: Colors.black, child: _buildBody()),
          ),
          if (_controller != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _PlayerControls(controller: _controller!),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_urlLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                  color: Color(0xFF00A8E8), strokeWidth: 3),
            ),
            SizedBox(height: 10),
            Text(
              'Loading video…',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final message = _urlError ?? _playbackError;
    if (message != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    if (_controller == null) return const SizedBox.shrink();
    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  final VideoPlayerController controller;

  const _PlayerControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Row(
          children: [
            IconButton(
              onPressed: () =>
                  value.isPlaying ? controller.pause() : controller.play(),
              icon: Icon(
                value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              color: const Color(0xFF00A8E8),
              tooltip: value.isPlaying ? 'Pause' : 'Play',
            ),
            Expanded(
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF00A8E8),
                  bufferedColor: Color(0xFF94A3B8),
                  backgroundColor: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _label(value.position),
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF5A6265),
              ),
            ),
          ],
        );
      },
    );
  }

  String _label(Duration d) {
    final total = d.inSeconds;
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }
}
