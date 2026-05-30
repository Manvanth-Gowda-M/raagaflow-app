import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/duration_formatter.dart';
import '../../features/player/domain/player_provider.dart';
import '../models/track_model.dart';
import 'shimmer_track_tile.dart';
import 'source_badge.dart';

class TrackTile extends ConsumerWidget {
  final TrackModel track;
  final List<TrackModel>? queue;
  final VoidCallback? onLongPress;

  const TrackTile({
    super.key,
    required this.track,
    this.queue,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.currentTrack?.id == track.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            ref.read(playerProvider.notifier).play(track, queue: queue);
          },
          onLongPress: onLongPress,
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
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                              Icons.equalizer_rounded,
                              color: AppColors.accent,
                              size: 22),
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
                // ─── Duration ───
                Text(
                  formatSeconds(track.durationSeconds),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
