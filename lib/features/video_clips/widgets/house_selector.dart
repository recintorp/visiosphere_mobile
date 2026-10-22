import 'package:flutter/material.dart';
import '../providers/video_clips_provider.dart';

/// "All Locations" plus one chip per camera in the signed-in user's facility.
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
      child: Align(
        alignment: Alignment.centerLeft,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((house) {
              final active = selectedHouseId == house.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  button: true,
                  selected: active,
                  label: house.name,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onSelect(house.id),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? (isDark
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFF00A8E8))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? Colors.transparent
                              : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        house.name,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? Colors.white
                              : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
