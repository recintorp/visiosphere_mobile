import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/facilities.dart';
import '../models/video_clip.dart';
import '../services/video_clips_service.dart';

/// Sort orders offered in the toolbar.
class SortOption {
  final String id;
  final String label;
  const SortOption(this.id, this.label);
}

/// Raised by [VideoClipsProvider.removeClips] when some deletes succeeded and
/// others did not, so the UI can report honestly instead of implying that
/// everything went.
class PartialDeleteException implements Exception {
  final int deleted;
  final int failed;
  final String message;
  PartialDeleteException(this.deleted, this.failed, this.message);
  @override
  String toString() => message;
}

class VideoClipsProvider extends ChangeNotifier {
  final _service = VideoClipsService();

  /// 'newest' stays the default: this is a monitoring archive, and the thing a
  /// nurse coming on shift needs first is what happened most recently.
  static const List<SortOption> sortOptions = [
    SortOption('newest', 'Newest first'),
    SortOption('oldest', 'Oldest first'),
    SortOption('type', 'Event type'),
    SortOption('severity', 'Most severe first'),
  ];

  /// Ranked so the orders that matter clinically sort first. Anything unlisted
  /// falls to the end rather than colliding at 0 with genuine emergencies.
  static const Map<String, int> _severityRank = {
    'Fall': 0,
    'Lying Down': 1,
    'Agitation': 2,
    'Inactivity': 3,
  };

  /// Sentinel for "no house filter".
  static const String allHouses = 'all';

  static const String _otherGroupId = '__other__';
  static const String _otherGroupName = 'Other Cameras';

  /// Matches the backend's own default window when `since` is omitted.
  static const String dateRangeLabel = 'Last 7 Days';

  List<VideoClip> _clips = [];
  List<CctvCamera> _cameraGroups = [];

  bool _isLoading = true;
  String? _errorMessage;
  bool _canDelete = false;

  String _selectedHouseId = allHouses;
  String _activeEventType = 'all';
  String _search = '';
  String _sortBy = 'newest';

  /// Ids ticked for bulk deletion. A Set, not a list: selection is membership,
  /// and every rebuild asks "is this card selected" once per card.
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canDelete => _canDelete;
  String get selectedHouseId => _selectedHouseId;
  String get activeEventType => _activeEventType;
  String get search => _search;
  String get sortBy => _sortBy;
  bool get selectionMode => _selectionMode;
  Set<String> get selectedIds => _selectedIds;

  /// Camera tiles for the current facility, as house filter chips.
  List<({String id, String name})> get houses =>
      _cameraGroups.map((c) => (id: c.cameraId, name: c.name)).toList();

  // -------------------------------------------------------------------------
  // Load
  // -------------------------------------------------------------------------
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _canDelete = await VideoClipsService.canDeleteClips();
    _cameraGroups = await VideoClipsService.cameraGroups();

    try {
      _clips = await _service.fetchVideoClips();
      _errorMessage = null;
    } catch (e) {
      debugPrint('[VideoClips] failed to load clips: $e');
      _errorMessage = 'Unable to load video clips. Please try again.';
      _clips = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Thumbnails are fetched SEPARATELY and after the fact, on purpose. They
    // are decoration: the grid is fully usable with gradient placeholders, so
    // nothing here should delay showing it. A failure is swallowed for the same
    // reason — a missing poster must never surface as "unable to load video
    // clips" when the clips loaded perfectly well.
    if (_clips.isNotEmpty) {
      try {
        final urls = await _service.fetchThumbnailUrls(
          _clips.map((c) => c.id).toList(),
        );
        if (urls.isNotEmpty) {
          _clips = _clips
              .map((c) => urls[c.id] != null ? c.copyWith(thumbnail: urls[c.id]) : c)
              .toList();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[VideoClips] thumbnails unavailable: $e');
      }
    }
  }

  // -------------------------------------------------------------------------
  // Filters
  // -------------------------------------------------------------------------
  void setSelectedHouseId(String id) {
    _selectedHouseId = id;
    notifyListeners();
  }

  void setActiveEventType(String id) {
    _activeEventType = id;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setSortBy(String id) {
    _sortBy = id;
    notifyListeners();
  }

  int _compare(VideoClip a, VideoClip b) {
    switch (_sortBy) {
      case 'oldest':
        return a.timestamp.compareTo(b.timestamp);
      case 'type':
        final byType = a.eventType.compareTo(b.eventType);
        return byType != 0 ? byType : b.timestamp.compareTo(a.timestamp);
      case 'severity':
        final rankA = _severityRank[a.eventType] ?? 1 << 30;
        final rankB = _severityRank[b.eventType] ?? 1 << 30;
        return rankA != rankB ? rankA - rankB : b.timestamp.compareTo(a.timestamp);
      default: // newest
        return b.timestamp.compareTo(a.timestamp);
    }
  }

  /// Filter -> group -> sort. Grouping is by camera and is not affected by the
  /// chosen order — sorting across groups would flatten the layout.
  List<ClipGroup> get groupedClips {
    final query = _search.trim().toLowerCase();

    final filtered = _clips.where((clip) {
      if (_activeEventType != 'all' && clip.eventType != _activeEventType) {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack =
            '${clip.eventType} ${clip.cameraName} ${clip.dateLabel}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();

    final feedIdToGroup = {for (final c in _cameraGroups) c.feedId!: c};

    final buckets = <String, List<VideoClip>>{
      for (final c in _cameraGroups) c.cameraId: <VideoClip>[],
    };
    final names = <String, String>{for (final c in _cameraGroups) c.cameraId: c.name};

    var hasOther = false;
    for (final clip in filtered) {
      final group = feedIdToGroup[clip.cameraName];
      if (group != null) {
        buckets[group.cameraId]!.add(clip);
      } else {
        // Unrecognised camera (a historical incident from a camera no longer
        // configured, or a cam_id in ai_core/.env that doesn't match
        // facilities.dart). Kept visible rather than silently dropped — a clip
        // vanishing without trace is worse than an odd group heading, and this
        // grouping is cosmetic: the backend already decided which incidents
        // this user may see at all.
        buckets.putIfAbsent(_otherGroupId, () => <VideoClip>[]);
        names[_otherGroupId] = _otherGroupName;
        buckets[_otherGroupId]!.add(clip);
        hasOther = true;
      }
    }

    for (final list in buckets.values) {
      list.sort(_compare);
    }

    var groups = buckets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => ClipGroup(
              houseId: e.key,
              houseName: names[e.key] ?? e.key,
              clips: e.value,
            ))
        .toList();

    // "Other Cameras" always last, regardless of insertion order.
    if (hasOther) {
      groups = [
        ...groups.where((g) => g.houseId != _otherGroupId),
        ...groups.where((g) => g.houseId == _otherGroupId),
      ];
    }

    if (_selectedHouseId != allHouses) {
      groups = groups.where((g) => g.houseId == _selectedHouseId).toList();
    }

    return groups;
  }

  List<VideoClip> get visibleClips =>
      groupedClips.expand((g) => g.clips).toList();

  List<VideoClip> get selectedClips =>
      visibleClips.where((c) => _selectedIds.contains(c.id)).toList();

  /// Record the real duration once a clip has actually been played.
  ///
  /// There is no backend field for it — the player reads it from the video's
  /// own metadata — so a card nobody has opened simply has no badge.
  void setClipDuration(String clipId, String duration) {
    final index = _clips.indexWhere((c) => c.id == clipId);
    if (index == -1 || _clips[index].duration == duration) return;
    _clips = List.of(_clips)..[index] = _clips[index].copyWith(duration: duration);
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Edit / delete
  // -------------------------------------------------------------------------
  /// Apply a correction and patch the one clip in place.
  ///
  /// Not a full reload: re-fetching would rebuild every group and re-request
  /// all the thumbnails — a lot of visible churn for a one-field change. The
  /// server's response is the source of truth for the new values, including the
  /// severity it derived.
  Future<void> editClip(String clipId, String incidentType, String note) async {
    final updated = await _service.updateClip(
      clipId,
      incidentType: incidentType,
      note: note,
    );
    final newType = updated['incidentType']?.toString() ?? incidentType;
    final newNote = updated['note']?.toString() ?? note;

    _clips = _clips
        .map((c) => c.id == clipId
            ? c.copyWith(
                rawIncidentType: newType,
                eventType: VideoClipsService.categoryForType(newType),
                note: newNote,
              )
            : c)
        .toList();
    notifyListeners();
  }

  /// Delete several recordings.
  ///
  /// Sequential, not in parallel: each delete is a round trip to the mini PC
  /// through the tunnel, and firing a dozen at once risks tripping the write
  /// rate limiter — which would surface as random failures that look like data
  /// loss. Slower and predictable beats faster and confusing here.
  ///
  /// Partial failure is reported honestly rather than swallowed. Only the clips
  /// that actually deleted leave the grid; the rest stay, still selected, so a
  /// retry is one tap and nothing silently vanishes from the UI while its file
  /// is still on disk.
  Future<void> removeClips(
    List<String> clipIds, {
    CancelToken? cancelToken,
    void Function(int current, int total)? onProgress,
  }) async {
    final deleted = <String>[];
    final failed = <String>[];

    for (final id in clipIds) {
      // Stop at the first sign the user pulled out. Clips already deleted stay
      // deleted — the files really are gone — but nothing further is attempted.
      if (cancelToken?.isCancelled ?? false) break;
      try {
        onProgress?.call(deleted.length + failed.length + 1, clipIds.length);
        await _service.deleteClip(id, cancelToken: cancelToken);
        deleted.add(id);
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) break;
        debugPrint('[VideoClips] delete failed for $id: $e');
        failed.add(id);
      } catch (e) {
        debugPrint('[VideoClips] delete failed for $id: $e');
        failed.add(id);
      }
    }

    if (deleted.isNotEmpty) {
      _clips = _clips.where((c) => !deleted.contains(c.id)).toList();
    }
    _selectedIds
      ..clear()
      ..addAll(failed);

    if (failed.isNotEmpty) {
      notifyListeners();
      throw PartialDeleteException(
        deleted.length,
        failed.length,
        deleted.isNotEmpty
            ? 'Deleted ${deleted.length}, but ${failed.length} could not be removed. Those are still selected.'
            : 'Could not delete ${failed.length} recording${failed.length > 1 ? 's' : ''}.',
      );
    }

    _selectionMode = false;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Selection
  // -------------------------------------------------------------------------
  void setSelectionMode(bool value) {
    _selectionMode = value;
    if (!value) _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelected(String clipId) {
    if (!_selectedIds.remove(clipId)) _selectedIds.add(clipId);
    notifyListeners();
  }

  /// Tick every clip currently visible under the active filters. Deliberately
  /// scoped to what is on screen — a "select all" that silently included clips
  /// hidden by a filter would delete things the user never saw.
  void selectAllVisible() {
    _selectedIds
      ..clear()
      ..addAll(visibleClips.map((c) => c.id));
    notifyListeners();
  }

  void exitSelectionMode() => setSelectionMode(false);
}
