/// One CCTV recording, as the Video Clips screen reads it.
///
/// Built from a raw Incident (see VideoClipsService.mapIncident). Two fields
/// have no backend source and are populated client-side:
///
///   - [duration] is read from the video element's own metadata once a clip is
///     actually played, so a card nobody has opened has none. The card hides
///     its badge rather than showing a "--:--" that would never resolve.
///   - [thumbnail] is a signed poster URL fetched in batch, separately and
///     after the fact. It can legitimately be absent (clips recorded before
///     ai_core wrote posters).
class VideoClip {
  final String id;

  /// The bucketed category ('Fall', 'Agitation', 'Inactivity', 'Lying Down'),
  /// used by the filter pills and the badge.
  final String eventType;

  /// The exact Incident.incidentType, used to seed the Edit dropdown.
  final String rawIncidentType;

  /// RAW Incident.location — the ai_core cam_id string, not a display name.
  /// This is the only reliable join key back to a camera tile.
  final String cameraName;

  final String? cameraId;
  final String note;
  final String? thumbnail;
  final String? duration;
  final String dateLabel;
  final String timeLabel;
  final DateTime timestamp;

  const VideoClip({
    required this.id,
    required this.eventType,
    required this.rawIncidentType,
    required this.cameraName,
    required this.dateLabel,
    required this.timeLabel,
    required this.timestamp,
    this.cameraId,
    this.note = '',
    this.thumbnail,
    this.duration,
  });

  VideoClip copyWith({
    String? eventType,
    String? rawIncidentType,
    String? note,
    String? thumbnail,
    String? duration,
  }) {
    return VideoClip(
      id: id,
      eventType: eventType ?? this.eventType,
      rawIncidentType: rawIncidentType ?? this.rawIncidentType,
      cameraName: cameraName,
      cameraId: cameraId,
      note: note ?? this.note,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      timestamp: timestamp,
    );
  }
}

/// One camera's clips, as rendered under a single heading.
class ClipGroup {
  final String houseId;
  final String houseName;
  final List<VideoClip> clips;

  const ClipGroup({
    required this.houseId,
    required this.houseName,
    required this.clips,
  });
}
