import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import '../providers/cctv_provider.dart';

class CameraFeedWidget extends StatelessWidget {
  final CctvCamera camera;

  const CameraFeedWidget({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF020617) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildFeedContent(isDark),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearOverlayGradient(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent(bool isDark) {
    if (camera.status != 'Active' || camera.url == null) {
      return _buildNoSignalView('NO SIGNAL', isDark);
    }

    return Mjpeg(
      isLive: true,
      stream: camera.url!,
      fit: BoxFit.cover,
      loading: (context) => _buildLoadingView(isDark),
      error: (context, error, stack) => _buildNoSignalView('CONNECTION LOST', isDark),
    );
  }

  Widget _buildLoadingView(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SYNCING FEED...',
          style: TextStyle(
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildNoSignalView(String message, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.videocam_off_outlined,
          size: 48,
          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.2),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isDark ? 0.3 : 0.4),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

class LinearOverlayGradient extends LinearGradient {
  const LinearOverlayGradient()
      : super(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: const [Colors.black87, Colors.transparent],
        );
}