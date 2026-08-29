import 'package:flutter/material.dart';
import '../providers/video_clips_provider.dart';

/// Search box, the (fixed) date-range label and the sort menu.
///
/// The date range is a plain label rather than a live picker: it states the
/// backend's own default window when `since` is omitted, and there is no
/// date-range control to wire it to.
class VideoClipsToolbar extends StatelessWidget {
  final String search;
  final ValueChanged<String> onSearchChanged;
  final String sortBy;
  final ValueChanged<String> onSortChanged;

  const VideoClipsToolbar({
    super.key,
    required this.search,
    required this.onSearchChanged,
    required this.sortBy,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final activeSort = VideoClipsProvider.sortOptions
        .firstWhere((o) => o.id == sortBy,
            orElse: () => VideoClipsProvider.sortOptions.first);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: TextField(
            onChanged: onSearchChanged,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: InputBorder.none,
              hintText: 'Search event, camera or date',
              hintStyle: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: muted),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 13, color: muted),
            const SizedBox(width: 6),
            Text(
              VideoClipsProvider.dateRangeLabel,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              initialValue: sortBy,
              onSelected: onSortChanged,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              itemBuilder: (context) => VideoClipsProvider.sortOptions
                  .map((o) => PopupMenuItem<String>(
                        value: o.id,
                        child: Text(
                          o.label,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ))
                  .toList(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 14, color: muted),
                    const SizedBox(width: 6),
                    Text(
                      activeSort.label,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: muted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
