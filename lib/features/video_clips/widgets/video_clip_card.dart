import 'package:flutter/material.dart';
import '../models/video_clip.dart';

/// Badge colour + label per event category. Mirrors the web's BADGE_STYLES.
class _Badge {
  final Color color;
  final String label;
  const _Badge(this.color, this.label);
}

const Map<String, _Badge> _badges = {
  'Fall': _Badge(Color(0xFFEF4444), 'FALL DETECTED'),
  'Agitation': _Badge(Color(0xFFA855F7), 'AGITATION DETECTED'),
  'Lying Down': _Badge(Color(0xFF3B82F6), 'LYING DOWN DETECTED'),
  'Inactivity': _Badge(Color(0xFFEAB308), 'INACTIVITY'),
};

/// One recording.
///
/// The duration badge is conditional: [VideoClip.duration] has no backend
/// source and is only ever populated once a clip has been played and its real
/// duration read from the player. A permanent "--:--" would look broken since
/// it would never resolve on a card nobody has opened.
///
/// The thumbnail is a signed poster URL. It can legitimately be absent (clips
/// recorded before ai_core wrote posters) or expire while the screen sits open,
/// so an image failure silently reverts to the gradient rather than showing a
/// broken-image icon.
class VideoClipCard extends StatelessWidget {
  final VideoClip clip;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canDelete;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelect;

  const VideoClipCard({
    super.key,
    required this.clip,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.canDelete,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badge = _badges[clip.eventType] ??
        _Badge(const Color(0xFF94A3B8), clip.eventType.toUpperCase());

    // The thumbnail paints the event badge, the time and (when known) the
    // duration straight onto the image, so none of it reached the a11y tree —
    // the scanner read them back as "unexposed text" over an unlabelled tap
    // target. Spoken as one description, plus the clip's own identity so two
    // cards never describe themselves the same way.
    final spoken = StringBuffer('${badge.label}, ${clip.cameraName}, '
        '${clip.dateLabel} ${clip.timeLabel}');
    if (clip.note.isNotEmpty) spoken.write(', note: ${clip.note}');
    if (clip.duration != null) spoken.write(', ${clip.duration}');
    final String selectPrefix = selected ? 'Selected. ' : 'Not selected. ';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? const Color(0xFF00A8E8)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // In selection mode the thumbnail ticks the checkbox instead of
          // opening the player. Opening a video on the way to deleting a dozen
          // clips would make bulk selection unusable.
          Semantics(
            button: true,
            label: selectionMode ? '$selectPrefix$spoken' : 'Play clip. $spoken',
            excludeSemantics: true,
            child: GestureDetector(
            onTap: selectionMode ? onToggleSelect : onSelect,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _Thumbnail(
                clip: clip,
                badge: badge,
                isDark: isDark,
                selectionMode: selectionMode,
                selected: selected,
              ),
            ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clip.dateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        clip.note.isNotEmpty ? clip.note : clip.cameraName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: clip.note.isNotEmpty
                              ? const Color(0xFF00A8E8)
                              : (isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF9DABB1)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Hidden during selection mode: per-card actions alongside a
                // bulk selection are two ways to do the same thing, and the
                // wrong one is destructive.
                if (!selectionMode)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    tooltip: 'Actions for ${badge.label} clip, '
                        '${clip.cameraName}, ${clip.dateLabel}',
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF9DABB1),
                    ),
                    onSelected: (value) {
                      if (value == 'view') onSelect();
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      _menuItem('view', 'View Clip', isDark),
                      _menuItem('edit', 'Edit Details', isDark),
                      // Deleting footage is admin-only. The backend enforces
                      // this independently on DELETE /incidents/:id/clip;
                      // hiding the entry only avoids offering an action that
                      // returns 403.
                      if (canDelete)
                        _menuItem('delete', 'Delete Clip', isDark,
                            color: const Color(0xFFE11D48)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, bool isDark,
      {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatefulWidget {
  final VideoClip clip;
  final _Badge badge;
  final bool isDark;
  final bool selectionMode;
  final bool selected;

  const _Thumbnail({
    required this.clip,
    required this.badge,
    required this.isDark,
    required this.selectionMode,
    required this.selected,
  });

  @override
  State<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<_Thumbnail> {
  bool _thumbFailed = false;

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final isDark = widget.isDark;
    final showThumb = clip.thumbnail != null && !_thumbFailed;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF00344A), Color(0xFF00212E)]
              : const [Color(0xFFEAF8FE), Color(0xFFD6F0FB)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showThumb)
            Image.network(
              clip.thumbnail!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                // A poster can 404 or its signed URL can expire while the
                // screen sits open. Fall back to the gradient rather than a
                // broken-image icon.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _thumbFailed = true);
                });
                return const SizedBox.shrink();
              },
            ),
          // Scrim only when there is an image behind it — the badges need
          // contrast over real footage, but it would look muddy over the
          // gradient placeholder.
          if (showThumb)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black38, Colors.transparent, Colors.black26],
                ),
              ),
              child: SizedBox.expand(),
            ),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: widget.badge.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.badge.label,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF00212E) : Colors.white)
                    .withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                clip.timeLabel,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF00212E),
                ),
              ),
            ),
          ),
          Center(
            child: widget.selectionMode
                ? Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.selected
                          ? const Color(0xFF00A8E8)
                          : (isDark ? const Color(0xFF00212E) : Colors.white)
                              .withValues(alpha: 0.85),
                      border: Border.all(
                        color: widget.selected
                            ? const Color(0xFF00A8E8)
                            : Colors.white70,
                        width: 2,
                      ),
                    ),
                    child: widget.selected
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : null,
                  )
                : Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00A8E8),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        size: 24, color: Colors.white),
                  ),
          ),
          if (clip.duration != null)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  clip.duration!,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
