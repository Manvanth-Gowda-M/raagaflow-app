import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shimmer_track_tile.dart';
import '../../domain/player_provider.dart';
import '../../../library/domain/library_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final track = playerState.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final isFav = ref.watch(
      libraryProvider.select((s) => s.favorites.any((t) => t.id == track.id)),
    );

    return GestureDetector(
      onTap: () => context.push('/player'),
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -150) {
            ref.read(playerProvider.notifier).skipToNext();
          } else if (details.primaryVelocity! > 150) {
            ref.read(playerProvider.notifier).skipToPrev();
          }
        }
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.22),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
                // ─── Main Content Row ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      // Album Artwork with subtle glow
                      Hero(
                        tag: 'album_art_${track.id}',
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: CachedNetworkImage(
                              imageUrl: track.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  const ShimmerBox(width: 46, height: 46),
                              errorWidget: (_, __, ___) => ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Track Title & Artist
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artist,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Favorite Toggle Button
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? AppColors.like : AppColors.textHint,
                          size: 20,
                        ),
                        onPressed: () =>
                            ref.read(libraryProvider.notifier).toggleFavorite(track),
                      ),
                      // Play / Pause / Loading Button
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
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                      const SizedBox(width: 2),
                      // Skip Next Button
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                        onPressed: () =>
                            ref.read(playerProvider.notifier).skipToNext(),
                      ),
                    ],
                  ),
                ),
                // ─── Embedded Slim Progress Bar at Bottom ───
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: playerState.isBuffering
                      ? LinearProgressIndicator(
                          color: AppColors.accent,
                          backgroundColor: Colors.transparent,
                          minHeight: 2.0,
                        )
                      : StreamBuilder<Duration>(
                          stream: ref.read(audioHandlerProvider).positionStream,
                          builder: (_, posSnap) {
                            return StreamBuilder<Duration?>(
                              stream: ref.read(audioHandlerProvider).durationStream,
                              builder: (_, durSnap) {
                                final pos = posSnap.data?.inMilliseconds ?? 0;
                                final dur = durSnap.data?.inMilliseconds ?? 0;
                                final progress = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;
                                return LinearProgressIndicator(
                                  value: progress,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                                  minHeight: 2.0,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
    );
  }
}
