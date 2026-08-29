import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/facilities.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../models/video_clip.dart';

/// One filter pill: the category id matched against VideoClip.eventType, and
/// the label shown on the pill.
class EventTypeOption {
  final String id;
  final String label;
  const EventTypeOption(this.id, this.label);
}

/// Mirrors the web's `services/videoClipsService.js`.
///
/// The JWT is attached automatically by DioClient's request interceptor and a
/// 401 triggers a global sign-out, so no auth handling is needed here — only
/// the 404 special case in [getClipVideoUrl].
class VideoClipsService {
  final Dio _dio = DioClient.instance;

  // -------------------------------------------------------------------------
  // Event type categories
  // -------------------------------------------------------------------------
  /// Incident.incidentType has more values than the filter pills show. Rather
  /// than inventing a new grouping, this reuses the same category mapping the
  /// backend's getWeeklyStats() applies server-side, so a "Prolonged Fall" clip
  /// shows under the same category everywhere in the app.
  ///
  /// NOTE ON PACING: there is no 'Pacing' value in the Incident enum — it was
  /// removed from ai_core — so a Pacing pill could only ever return zero
  /// results. Absent rather than dead. If Pacing is reinstated in the detector
  /// AND added back to the Incident enum, restore the entry here and the
  /// matching pill below.
  static const Map<String, String> _eventTypeCategory = {
    'Fall': 'Fall',
    'Prolonged Fall': 'Fall',
    'Agitation': 'Agitation',
    'Inactivity': 'Inactivity',
    'Inactivity (Posture)': 'Inactivity',
    'Lying Down': 'Lying Down',
    // 'Unusual Movement' and 'False Alarm' intentionally have no bucket — they
    // still render via the card's generic fallback badge, they just aren't
    // filterable by a dedicated pill.
  };

  static String categoryForType(String? incidentType) =>
      _eventTypeCategory[incidentType] ?? (incidentType ?? 'Event');

  /// Pills shown in EventFilterPills. 'All Events' plus the categories above.
  static const List<EventTypeOption> eventTypes = [
    EventTypeOption('all', 'All Events'),
    EventTypeOption('Fall', 'Fall Detection'),
    EventTypeOption('Agitation', 'Agitation'),
    EventTypeOption('Lying Down', 'Lying Down'),
    EventTypeOption('Inactivity', 'Inactivity'),
  ];

  /// Event types the backend will accept for a reclassification. Mirrors the
  /// enum on `backend/models/Incident.js` — the server validates against its
  /// own schema regardless, so this list only shapes the dropdown.
  static const List<String> incidentTypes = [
    'Fall',
    'Prolonged Fall',
    'Lying Down',
    'Agitation',
    'Inactivity',
    'Inactivity (Posture)',
    'Unusual Movement',
    'False Alarm',
  ];

  // -------------------------------------------------------------------------
  // Formatting
  // -------------------------------------------------------------------------
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String formatDateLabel(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  static String formatTimeLabel(DateTime d) {
    final isPm = d.hour >= 12;
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${_two(hour12)}:${_two(d.minute)}:${_two(d.second)} ${isPm ? 'PM' : 'AM'}';
  }

  // -------------------------------------------------------------------------
  // Incident -> clip
  // -------------------------------------------------------------------------
  /// Maps one raw Incident to the shape the cards and player read.
  ///
  /// `duration` and `thumbnail` are deliberately left null — neither exists on
  /// Incident. `videoUrl` is deliberately NOT resolved here either: minting a
  /// signed URL for every clip in a list the user is only browsing would create
  /// tokens for clips nobody opens. Call [getClipVideoUrl] when one is opened.
  static VideoClip mapIncident(Map<String, dynamic> incident) {
    final createdAt =
        DateTime.tryParse(incident['createdAt']?.toString() ?? '')?.toLocal() ??
            DateTime.now();
    final rawType = incident['incidentType']?.toString() ?? 'Event';
    return VideoClip(
      id: incident['_id']?.toString() ?? '',
      eventType: categoryForType(rawType),
      rawIncidentType: rawType,
      cameraName: incident['location']?.toString() ?? 'Unknown',
      cameraId: incident['cameraId']?.toString(),
      note: incident['note']?.toString() ?? '',
      dateLabel: formatDateLabel(createdAt),
      timeLabel: formatTimeLabel(createdAt),
      timestamp: createdAt,
    );
  }

  // -------------------------------------------------------------------------
  // API calls
  // -------------------------------------------------------------------------
  /// Fetch recent CCTV incidents that have a recorded clip attached.
  ///
  /// Facility isolation is NOT applied here and should not be — GET /incidents
  /// runs behind verifyToken on the backend, which auto-scopes every query to
  /// the caller's facility. A client-side filter on top would be redundant, and
  /// as a safeguard it would be meaningless. The backend is the enforcement
  /// point.
  Future<List<VideoClip>> fetchVideoClips({String? since, int limit = 100}) async {
    final response = await _dio.get(
      ApiConstants.incidentBase,
      queryParameters: {
        'source': 'cctv',
        'since': ?since,
        'limit': limit,
        // showDismissed is ESSENTIAL here, not optional. GET /incidents defaults
        // to hiding dismissed incidents because its primary caller is the alert
        // inbox, where "dismissed" means "I have seen this notification".
        //
        // This screen is not an inbox. It is the recording archive. Dismissing a
        // notification must never hide the footage of the event from review.
        'showDismissed': 'true',
      },
    );

    final data = response.data;
    final items = (data is Map<String, dynamic> ? data['items'] : data) as List<dynamic>? ?? [];

    // Only incidents with a clip already attached. An incident can exist before
    // its clip finishes encoding (ai_core's cctv_alert fires first,
    // cctv_alert_clip follows ~10-45s later) — those simply don't appear yet,
    // rather than showing a card with nothing playable behind it.
    return items
        .whereType<Map<String, dynamic>>()
        .where((i) => (i['clipPath']?.toString() ?? '').isNotEmpty)
        .map(mapIncident)
        .toList();
  }

  /// Resolve a short-lived, signed playback URL for one clip.
  ///
  /// Call this only when the user actually opens a clip, never for a whole
  /// list — the backend mints tokens with a short TTL on the assumption that
  /// they are requested right before use.
  ///
  /// Returns null when no clip is available yet (still recording, or the file
  /// went missing on disk). A normal state to handle in the UI, not an error.
  Future<String?> getClipVideoUrl(String incidentId) async {
    try {
      final response = await _dio.get('${ApiConstants.incidentBase}/$incidentId/video-url');
      final data = response.data;
      if (data is Map && data['url'] is String) return data['url'] as String;
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Signed poster URLs for many clips at once: { incidentId: url }.
  ///
  /// Batched deliberately. One request per card would be a dozen round trips
  /// through the tunnel on every load, and folding poster URLs into the clip
  /// list would mint a signed token for every incident, most of which nobody
  /// ever looks at.
  ///
  /// Ids missing from the response have no poster — the card keeps its gradient
  /// placeholder. That is a normal state, not an error.
  Future<Map<String, String>> fetchThumbnailUrls(List<String> ids) async {
    if (ids.isEmpty) return {};
    final response = await _dio.get(
      '${ApiConstants.incidentBase}/thumbnail-urls',
      queryParameters: {'ids': ids.join(',')},
    );
    final data = response.data;
    if (data is! Map) return {};
    return data.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  /// Correct the record attached to a recording.
  ///
  /// The video itself is immutable — "editing a clip" means fixing what it was
  /// labelled as, which is the part that is ever actually wrong. Reclassifying
  /// also moves severity server-side, so the dashboard totals follow the
  /// correction.
  Future<Map<String, dynamic>> updateClip(
    String incidentId, {
    required String incidentType,
    required String note,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.incidentBase}/$incidentId/clip',
      data: {'incidentType': incidentType, 'note': note},
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Delete the recording from the mini PC.
  ///
  /// The INCIDENT is kept — only the video goes. Removing the incident too
  /// would let anyone quietly lower the facility's fall count by deleting the
  /// evidence. The backend restricts this to a Facility Admin and writes an
  /// audit entry.
  Future<void> deleteClip(String incidentId, {CancelToken? cancelToken}) async {
    await _dio.delete(
      '${ApiConstants.incidentBase}/$incidentId/clip',
      cancelToken: cancelToken,
      options: Options(
        // The backend has to reach the mini PC over the tunnel to remove the
        // file, so a stalled recorder would otherwise hang on the default
        // receive timeout. 45s is longer than the backend's own 15s abort, so a
        // real backend error still surfaces as itself rather than as a timeout.
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
      ),
    );
  }

  /// True if the signed-in user may delete recordings. The backend enforces
  /// this independently on DELETE /incidents/:id/clip; this only decides
  /// whether to render the control, so the worst case for a non-admin is a 403
  /// they can see, not access they should not have.
  static Future<bool> canDeleteClips() async {
    final role = await SecureStorageService.getUserRole();
    return role == 'Facility Admin';
  }

  /// Camera tiles for the signed-in user's facility, shaped to both display a
  /// facility-appropriate name and join incidents to the right group by feedId.
  ///
  /// Cameras with no feedId ("Pending Installation") are excluded: they cannot
  /// have produced incidents, so they would only ever render as an empty group.
  static Future<List<CctvCamera>> cameraGroups() async {
    final facility = await SecureStorageService.getFacility();
    return Facilities.camerasFor(facility).where((c) => c.feedId != null).toList();
  }
}
