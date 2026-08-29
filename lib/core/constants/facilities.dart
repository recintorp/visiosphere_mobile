/// facilities.dart — the single source of truth for tenancy on mobile.
///
/// VisioSphere serves two independent care facilities. Their data must never
/// mix: staff, residents, guardians, assessments and incidents all belong to
/// exactly one facility.
///
/// This file mirrors the web's `constants/houses.js`, `constants/cameras.js`
/// and `constants/idRoles.js`, which in turn mirror `backend/config/facilities.js`.
/// The BACKEND is authoritative and validates every write against it — nothing
/// here is a security boundary. Its job is to stop the UI from offering a user
/// something their facility does not own, which the backend would then reject.
///
/// HOW A USER GETS THEIR FACILITY — nobody ever types or selects it. The id
/// prefix carries both facility and role:
///
///                  Grace's           Saint Anthony
///   Admin          `A-<yr><nn>`      `STA-<yr><nn>`
///   Nurse          `N-<yr><nn>`      `STN-<yr><nn>`
///   Guardian       `G-<yr><nn>`      `STG-<yr><nn>`
///   Resident       `E-<yy><mm><nn>`  (shared by both facilities)
///
/// Nothing here may be hardcoded to a single prefix. A `startsWith('A-')` check
/// is what rejected STA-202601 at login with "Invalid format or credentials
/// provided", and a `startsWith('N-')` check would now do the same to STN- ids.
library;

import 'dart:convert';


/// What an id prefix tells us. `facility` is null for prefixes shared by both
/// facilities (currently only 'E' for residents), which identifies the role but
/// carries no tenancy.
class IdInfo {
  final String prefix;
  final String? facility;
  final String role;

  const IdInfo({required this.prefix, required this.facility, required this.role});
}

/// One camera tile.
///
/// `feedId` is the ai_core cam_id backing this tile. It drives BOTH the live
/// stream URL and the Active/Inactive badge. A tile with a null feedId is a
/// placeholder — no stream, always Inactive.
///
/// A camera's facility comes from `backend/config/facilities.js` CAMERA_FACILITY,
/// keyed on that same cam_id. That mapping is what routes an alert to the right
/// facility's dashboard, socket room and staff push notifications — so a new
/// camera must be added in THREE places: `ai_core/.env` (`CAM_<n>_*`), the backend
/// CAMERA_FACILITY map, and this file.
class CctvCamera {
  final String cameraId;
  final String name;
  final String location;
  final String? feedId;

  const CctvCamera({
    required this.cameraId,
    required this.name,
    required this.location,
    this.feedId,
  });

  /// A tile is Active only when it is backed by a feed. Cameras with no feedId
  /// are always Inactive — an over-report would tell staff a camera is watching
  /// a resident when it isn't.
  String get status => feedId != null ? 'Active' : 'Inactive';

  /// URL-encoded path segment on the AI core (e.g. 'Living%20Room').
  /// Null for cameras with no live feed.
  String? get streamPath => feedId == null ? null : Uri.encodeComponent(feedId!);
}

class Facilities {
  Facilities._();

  static const String graces = 'GRACES';
  static const String saintAnthony = 'SAINT_ANTHONY';

  static const Map<String, String> names = {
    graces: "Grace's Home for the Aged",
    saintAnthony: 'Saint Anthony de Padua Home Care Center',
  };

  /// Sentinel used by the house filter pills to mean "no house filter".
  static const String allHouses = 'Overall Facility';

  // ---------------------------------------------------------------------
  // Houses
  // ---------------------------------------------------------------------
  /// Houses belong to a facility. A Grace's admin must never be offered a Saint
  /// Anthony house, or they could assign a resident across the tenant boundary —
  /// the backend would reject the write, but the UI should not offer it at all.
  static const Map<String, List<String>> _houses = {
    graces: [
      'House of St. Charbel',
      'House of St. Francis',
      'House of St. Gabriel',
      'House of St. Rose of Lima',
      'House of St. Sebastian',
      'Louis S. Coson Hall',
    ],
    saintAnthony: [
      'House of Saint Anthony',
    ],
  };

  /// Houses for a facility.
  ///
  /// Returns [] for an unknown facility rather than falling back to every house —
  /// an empty dropdown is an obvious bug report, whereas a silent fallback would
  /// quietly re-introduce the cross-facility leak this exists to prevent.
  static List<String> housesFor(String? facility) => _houses[facility] ?? const [];

  /// Whether "house" is a meaningful choice at this facility.
  ///
  /// Houses are a Grace's concept: it is split across six of them, so which
  /// house a nurse or resident belongs to carries real information. Saint
  /// Anthony is a single building — everyone there is in the same place, so a
  /// House row shows the same string on every card and a House dropdown offers
  /// exactly one option. Both are noise, and the dropdown is worse than noise
  /// because it implies a decision that does not exist.
  ///
  /// Driven off the house count rather than a `== graces` check, so a second
  /// single-house facility gets the right behaviour for free.
  static bool hasHouseChoice(String? facility) => housesFor(facility).length > 1;

  /// The house to stamp on a new record when there is no choice to offer.
  /// Null when the facility genuinely has several (the user must pick) or is
  /// unknown.
  static String? soleHouseFor(String? facility) {
    final list = housesFor(facility);
    return list.length == 1 ? list.first : null;
  }

  /// Which facility a house belongs to, or null if unrecognised.
  static String? facilityForHouse(String? house) {
    for (final entry in _houses.entries) {
      if (entry.value.contains(house)) return entry.key;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Cameras
  // ---------------------------------------------------------------------
  /// Cameras per facility — FULLY separated. Each facility has its own physical
  /// rig, its own ai_core feed, and therefore its own detections and alerts.
  ///
  /// Grace's is not deployed yet — no camera on site, so every tile is a
  /// placeholder. When a rig is installed: add a `CAM_<n>` slot in `ai_core/.env`,
  /// then set `feedId` here to match its cam_id.
  static const Map<String, List<CctvCamera>> _cameras = {
    graces: [
      CctvCamera(
        cameraId: 'CAM-002',
        name: 'House of Gabriel',
        location: 'Pending Installation',
      ),
      CctvCamera(
        cameraId: 'CAM-001',
        name: 'House of Charbel',
        location: 'Pending Installation',
      ),
      CctvCamera(
        cameraId: 'CAM-003',
        name: 'Future CCTV 1',
        location: 'Pending Installation',
      ),
      CctvCamera(
        cameraId: 'CAM-004',
        name: 'Future CCTV 2',
        location: 'Pending Installation',
      ),
    ],
    saintAnthony: [
      CctvCamera(
        cameraId: 'STA-CAM-001',
        name: 'Living Room',
        location: 'IP Camera · CCTV',
        // Saint Anthony's own rig — CAM_1_ID=Living Room in ai_core/.env.
        feedId: 'Living Room',
      ),
      CctvCamera(
        cameraId: 'STA-CAM-002',
        name: 'Future CCTV 1',
        location: 'Pending Installation',
      ),
    ],
  };

  /// Cameras the given facility may see.
  ///
  /// Returns [] for an unknown facility rather than falling back to every camera —
  /// an empty grid is an obvious bug report, whereas a silent fallback would show
  /// one facility's live video to the other.
  static List<CctvCamera> camerasFor(String? facility) =>
      _cameras[facility] ?? const [];

  // ---------------------------------------------------------------------
  // Id prefixes
  // ---------------------------------------------------------------------
  /// prefix -> { facility, role }. facility null = shared by both facilities.
  ///
  /// Keep in sync with `backend/config/facilities.js` `idPrefixes`, which is
  /// authoritative — the backend validates against it.
  static const Map<String, IdInfo> _prefixIndex = {
    'A':   IdInfo(prefix: 'A',   facility: graces,       role: 'admin'),
    'N':   IdInfo(prefix: 'N',   facility: graces,       role: 'nurse'),
    'G':   IdInfo(prefix: 'G',   facility: graces,       role: 'guardian'),
    'STA': IdInfo(prefix: 'STA', facility: saintAnthony, role: 'admin'),
    'STN': IdInfo(prefix: 'STN', facility: saintAnthony, role: 'nurse'),
    'STG': IdInfo(prefix: 'STG', facility: saintAnthony, role: 'guardian'),
    'E':   IdInfo(prefix: 'E',   facility: null,         role: 'resident'),
  };

  /// Every id: 1-4 capital letters, hyphen, then 6 digits.
  static final RegExp _idShape = RegExp(r'^[A-Z]{1,4}-\d{6}$');
  static final RegExp _prefixShape = RegExp(r'^([A-Z]{1,4})-');

  /// { prefix, facility, role } or null when the id is unrecognised.
  static IdInfo? describeId(String? id) {
    final value = (id ?? '').trim().toUpperCase();
    if (!_idShape.hasMatch(value)) return null;
    final match = _prefixShape.firstMatch(value);
    if (match == null) return null;
    return _prefixIndex[match.group(1)];
  }

  /// 'admin' | 'nurse' | 'guardian' | 'resident' | null
  static String? roleOf(String? id) => describeId(id)?.role;

  /// Facility implied by the id, or null for shared/unknown prefixes.
  static String? facilityOf(String? id) => describeId(id)?.facility;

  static bool isAdminId(String? id) => roleOf(id) == 'admin';
  static bool isNurseId(String? id) => roleOf(id) == 'nurse';
  static bool isGuardianId(String? id) => roleOf(id) == 'guardian';
  static bool isResidentId(String? id) => roleOf(id) == 'resident';

  static bool isEmail(String? value) => (value ?? '').contains('@');

  /// True when the value could be a sign-in identifier at all.
  static bool isValidLoginIdentifier(String? value) =>
      isEmail(value) || isAdminId(value) || isNurseId(value) || isGuardianId(value);

  // ---------------------------------------------------------------------
  // Facility from the JWT
  // ---------------------------------------------------------------------
  /// Pull the `facility` claim out of a JWT payload.
  ///
  /// The login RESPONSE body does not carry the facility — the token does (see
  /// `backend/services/adminAuthService.js`, which signs `facility` into every
  /// token). The web reads it the same way in `pages/Login.jsx`.
  ///
  /// Returns null when the claim is absent or the token is malformed. A token
  /// minted before facility separation has no claim; the backend rejects those
  /// with a 401 telling the user to sign in again, so there is nothing to guess.
  static String? facilityFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      // base64Url in a JWT is unpadded; normalize() restores the padding
      // base64Url.decode() requires.
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = json.decode(payload);
      if (claims is! Map) return null;
      final facility = claims['facility'];
      return (facility is String && facility.isNotEmpty) ? facility : null;
    } catch (_) {
      return null;
    }
  }
}
