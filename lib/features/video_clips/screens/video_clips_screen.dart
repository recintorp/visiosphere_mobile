import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_clip.dart';
import '../providers/video_clips_provider.dart';
import '../widgets/delete_clip_dialog.dart';
import '../widgets/edit_clip_modal.dart';
import '../widgets/event_filter_pills.dart';
import '../widgets/house_selector.dart';
import '../widgets/video_clip_card.dart';
import '../widgets/video_clips_toolbar.dart';
import '../widgets/video_player_modal.dart';

/// The recording archive: every CCTV incident that has a clip attached,
/// grouped by camera. Mirrors the web's Video Clips page.
class VideoClipsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const VideoClipsScreen({super.key, this.onMenuTap});

  @override
  State<VideoClipsScreen> createState() => _VideoClipsScreenState();
}

class _VideoClipsScreenState extends State<VideoClipsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<VideoClipsProvider>().load();
    });
  }

  Future<void> _openPlayer(VideoClip clip) async {
    final provider = context.read<VideoClipsProvider>();
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      // Keyed by clip id so opening a different clip builds a fresh player
      // rather than reusing one still holding the previous controller.
      builder: (_) => VideoPlayerModal(
        key: ValueKey(clip.id),
        clip: clip,
        onDuration: (d) => provider.setClipDuration(clip.id, d),
      ),
    );
  }

  Future<void> _openEdit(VideoClip clip) async {
    final provider = context.read<VideoClipsProvider>();
    await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => EditClipModal(clip: clip, onSave: provider.editClip),
    );
  }

  Future<void> _confirmDelete(List<VideoClip> clips) async {
    if (clips.isEmpty) return;
    final provider = context.read<VideoClipsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final done = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => DeleteClipDialog(clips: clips, onConfirm: provider.removeClips),
    );

    if (done == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            clips.length > 1
                ? '${clips.length} recordings deleted.'
                : 'Recording deleted.',
            style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Consumer<VideoClipsProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                _buildHeader(context, provider, isDark),
                Expanded(child: _buildBody(provider, isDark)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, VideoClipsProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                ),
                child: IconButton(
                  tooltip: 'Open navigation menu',
                  icon: Icon(Icons.menu_rounded,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      size: 22),
                  onPressed:
                      widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video Clips',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Review detected events from your cameras.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: provider.isLoading ? null : provider.load,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                tooltip: 'Reload clips',
              ),
            ],
          ),
          const SizedBox(height: 14),
          EventFilterPills(
            activeEventType: provider.activeEventType,
            onChanged: provider.setActiveEventType,
          ),
          const SizedBox(height: 12),
          VideoClipsToolbar(
            search: provider.search,
            onSearchChanged: provider.setSearch,
            sortBy: provider.sortBy,
            onSortChanged: provider.setSortBy,
          ),
          // Sits directly under the sort menu, right-aligned to it. Selection
          // controls are only offered to users who may actually delete —
          // showing "Select to delete" to someone whose every delete returns
          // 403 is worse than not showing it at all.
          if (provider.canDelete) ...[
            const SizedBox(height: 10),
            _buildSelectionControls(provider, isDark),
          ],
          const SizedBox(height: 12),
          HouseSelector(
            houses: provider.houses,
            selectedHouseId: provider.selectedHouseId,
            onSelect: provider.setSelectedHouseId,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionControls(VideoClipsProvider provider, bool isDark) {
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (!provider.selectionMode) {
      return Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: () => provider.setSelectionMode(true),
          icon: const Icon(Icons.checklist_rounded, size: 16),
          label: const Text(
            'Select to delete',
            style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11.5,
                fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : const Color(0xFF00212E),
            side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            minimumSize: const Size(48, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Row(
      children: [
        Text(
          '${provider.selectedIds.length} selected',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF00212E),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: provider.selectAllVisible,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text('Select all',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: muted)),
        ),
        TextButton(
          onPressed: provider.exitSelectionMode,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text('Cancel',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: muted)),
        ),
        const SizedBox(width: 4),
        ElevatedButton(
          onPressed: provider.selectedIds.isEmpty
              ? null
              : () => _confirmDelete(provider.selectedClips),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE11D48),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            minimumSize: const Size(48, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Delete',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _buildBody(VideoClipsProvider provider, bool isDark) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                  color: Color(0xFF00A8E8), strokeWidth: 3),
            ),
            SizedBox(height: 12),
            Text('Loading clips...',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE11D48),
            ),
          ),
        ),
      );
    }

    final groups = provider.groupedClips;
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined,
                size: 44,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text('No clips found',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text('Try adjusting your filters or search.',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      color: const Color(0xFF00A8E8),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      group.houseName,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${group.clips.length}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // 16:9 thumbnail plus the footer row.
                    childAspectRatio: 0.98,
                  ),
                  itemCount: group.clips.length,
                  itemBuilder: (context, i) {
                    final clip = group.clips[i];
                    return VideoClipCard(
                      clip: clip,
                      canDelete: provider.canDelete,
                      selectionMode: provider.selectionMode,
                      selected: provider.selectedIds.contains(clip.id),
                      onToggleSelect: () => provider.toggleSelected(clip.id),
                      onSelect: () => _openPlayer(clip),
                      onEdit: () => _openEdit(clip),
                      onDelete: () => _confirmDelete([clip]),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
