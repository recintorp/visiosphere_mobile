import 'package:flutter/material.dart';
import '../providers/video_clips_provider.dart';

/// "All Locations" plus one chip per camera in the signed-in user's facility.
///
/// The chips come from the facility's camera list, so a Grace's user never sees
/// a Saint Anthony camera and vice versa.
class HouseSelector extends StatelessWidget {
  final List<({String id, String name})> houses;
  final String selectedHouseId;
  final ValueChanged<String> onSelect;

  const HouseSelector({
    super.key,
    required this.houses,
    required this.selectedHouseId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final entries = <({String id, String name})>[
      (id: VideoClipsProvider.allHouses, name: 'All Locations'),
      ...houses,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: entries.map((h) {
          final active = selectedHouseId == h.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(h.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? (isDark ? const Color(0xFF0284C7) : const Color(0xFF00A8E8))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? Colors.transparent
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  h.name,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
