import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/shimmer_track_tile.dart';
import '../../domain/player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final track = playerState.currentTrack;
    if (track == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/player'),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.15), width: 0.5),
              ),
            ),
            child: Stack(
              children: [
                // Content Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'album_art_${track.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: track.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                const ShimmerBox(width: 48, height: 48),
                            errorWidget: (_, __, ___) => ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.title,
                                style: AppTextStyles.trackTitle.copyWith(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(track.artist,
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // ─── Play/Pause/Buffer Button ───
                      GestureDetector(
                        onTap: () {
                          if (!playerState.isBuffering) {
                            ref.read(playerProvider.notifier).togglePlayPause();
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: playerState.isBuffering
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.black),
                                    ),
                                  )
                                : Icon(
                                    playerState.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    key: ValueKey(playerState.isPlaying),
                                    color: Colors.black,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.skip_next_rounded,
                            color: AppColors.textPrimary, size: 24),
                        onPressed: () =>
                            ref.read(playerProvider.notifier).skipToNext(),
                      ),
                    ],
                  ),
                ),
                // Glowing/Shimmering Loading Bar at the bottom
                if (playerState.isBuffering)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      color: AppColors.accent,
                      backgroundColor: Colors.transparent,
                      minHeight: 2,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
