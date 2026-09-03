import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/duration_formatter.dart';
import '../../features/downloads/domain/download_provider.dart';
import '../../features/library/domain/library_provider.dart';
import '../../features/player/domain/player_provider.dart';
import '../models/download_model.dart';
import '../models/track_model.dart';
import 'shimmer_track_tile.dart';
import 'source_badge.dart';
import 'mini_equalizer_bars.dart';

class TrackTile extends ConsumerWidget {
  final TrackModel track;
  final List<TrackModel>? queue;
  final VoidCallback? onLongPress;
  final bool showDownloadButton;
  final bool isSelectable;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const TrackTile({
    super.key,
    required this.track,
    this.queue,
    this.onLongPress,
    this.showDownloadButton = true,
    this.isSelectable = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

  void _showTrackOptions(BuildContext context, WidgetRef ref) {
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final isDownloaded = downloadNotifier.isDownloaded(track.id);
    final isFav = ref.read(libraryProvider).favorites.any((t) => t.id == track.id);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: track.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Image.asset(
                          'assets/images/app_icon.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: AppTextStyles.trackTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.artist,
                            style: AppTextStyles.trackArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? AppColors.like : AppColors.textPrimary,
                  ),
                  title: Text(isFav ? 'Remove from Favorites' : 'Add to Favorites',
                      style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(libraryProvider.notifier).toggleFavorite(track);
                  },
                ),
                ListTile(
                  leading: Icon(
                    isDownloaded ? Icons.delete_outline_rounded : Icons.download_rounded,
                    color: isDownloaded ? AppColors.secondary : AppColors.accent,
                  ),
                  title: Text(
                    isDownloaded ? 'Remove Download' : 'Download for Offline',
                    style: TextStyle(
                      color: isDownloaded ? AppColors.secondary : AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: isDownloaded
                      ? Text('Keeps track in library, removes offline copy',
                          style: TextStyle(color: AppColors.textHint, fontSize: 11))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isDownloaded) {
                      downloadNotifier.removeDownload(track.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed offline copy of "${track.title}"'),
                          backgroundColor: AppColors.surfaceContainerHigh,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      downloadNotifier.downloadTrack(track);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Downloading "${track.title}"...'),
                          backgroundColor: AppColors.surfaceContainerHigh,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.playlist_add_rounded, color: AppColors.textPrimary),
                  title: Text('Add to Playlist', style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddToPlaylistDialog(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref) {
    final playlists = ref.read(libraryProvider).playlists;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text('Add to Playlist', style: TextStyle(color: AppColors.textPrimary)),
        content: playlists.isEmpty
            ? Text('No playlists created yet. Create one in Library.',
                style: TextStyle(color: AppColors.textSecondary))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (_, i) {
                    final pl = playlists[i];
                    return ListTile(
                      title: Text(pl.name, style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text('${pl.tracks.length} songs',
                          style: TextStyle(color: AppColors.textHint)),
                      onTap: () {
                        ref.read(libraryProvider.notifier).addTrackToPlaylist(pl.id, track);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to ${pl.name}'),
                            backgroundColor: AppColors.accent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.currentTrack?.id == track.id;

    // Watch download state
    final downloadState = ref.watch(downloadProvider);
    final isDownloaded = downloadState.downloads.any((d) => d.songId == track.id);
    final queueItem = downloadState.queue.cast<DownloadQueueItem?>().firstWhere(
          (q) => q?.track.id == track.id,
          orElse: () => null,
        );

    final isDownloading = queueItem?.status == DownloadStatus.downloading;
    final isQueued = queueItem?.status == DownloadStatus.queued;
    final downloadProgress = queueItem?.progress ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (isSelectable) {
              onSelectChanged?.call(!isSelected);
            } else {
              ref.read(playerProvider.notifier).play(track, queue: queue);
            }
          },
          onLongPress: onLongPress ?? () => _showTrackOptions(context, ref),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isPlaying
                  ? AppColors.accent.withValues(alpha: 0.08)
                  : Colors.transparent,
              border: isPlaying
                  ? Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2), width: 0.8)
                  : null,
            ),
            child: Row(
              children: [
                if (isSelectable) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: onSelectChanged,
                    activeColor: AppColors.accent,
                    checkColor: Colors.black,
                  ),
                  const SizedBox(width: 4),
                ],
                // ─── Album Art ───
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: track.imageUrl,
                        width: 52,
                        height: 52,
                        memCacheWidth: 112,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const ShimmerBox(width: 52, height: 52),
                        errorWidget: (_, __, ___) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    if (isPlaying)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: MiniEqualizerBars(
                              isPlaying: playerState.isPlaying,
                              size: 18,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // ─── Track Info ───
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: AppTextStyles.trackTitle.copyWith(
                          color: isPlaying
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              track.artist,
                              style: AppTextStyles.trackArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SourceBadge(source: track.source),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ─── Download Action Button / Indicator ───
                if (showDownloadButton && !isSelectable) ...[
                  if (isDownloaded)
                    IconButton(
                      icon: Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
                      tooltip: 'Downloaded (Offline Ready)',
                      onPressed: () => _showTrackOptions(context, ref),
                    )
                  else if (isDownloading || isQueued)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: isDownloading && downloadProgress > 0 ? downloadProgress : null,
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(AppColors.accent),
                            backgroundColor: AppColors.surfaceContainerHighest,
                          ),
                          Text(
                            isDownloading ? '${(downloadProgress * 100).toInt()}%' : '...',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.download_for_offline_outlined,
                          color: AppColors.textHint, size: 22),
                      tooltip: 'Download Song',
                      onPressed: () {
                        ref.read(downloadProvider.notifier).downloadTrack(track);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading "${track.title}"...'),
                            backgroundColor: AppColors.surfaceContainerHigh,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                ],

                // ─── Duration & More Menu ───
                if (!isSelectable) ...[
                  Text(
                    formatSeconds(track.durationSeconds),
                    style: AppTextStyles.caption,
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: AppColors.textHint, size: 18),
                    onPressed: () => _showTrackOptions(context, ref),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
