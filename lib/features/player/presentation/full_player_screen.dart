import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../shared/widgets/shimmer_track_tile.dart';
import '../../../shared/widgets/source_badge.dart';
import '../../../core/theme/visualizer_provider.dart';
import '../../library/domain/library_provider.dart';
import '../domain/player_provider.dart';
import 'widgets/ambient_visualizer.dart';
import 'widgets/vinyl_visualizer.dart';
import 'widgets/waveform_seeker.dart';
class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _breathAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PlayerState>(playerProvider, (previous, next) {
      if (next.lastError != null && next.lastError != previous?.lastError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.lastError!),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(playerProvider.notifier).clearError();
      }
    });

    final playerState = ref.watch(playerProvider);
    final track = playerState.currentTrack;
    final handler = ref.read(audioHandlerProvider);
    final visualizerStyle = ref.watch(visualizerProvider);

    // Sync breathing scale with playback state
    if (playerState.isPlaying) {
      _breathCtrl.repeat(reverse: true);
    } else {
      _breathCtrl.stop();
    }

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: Text('Nothing playing',
                style: TextStyle(color: AppColors.textHint))),
      );
    }



    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ───
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textPrimary, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('Now Playing',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption
                            .copyWith(fontSize: 12, letterSpacing: 1)),
                  ),
                  // Spacer to balance the back arrow and keep title centred
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ─── Visualizer Area ───
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Builder(
                  builder: (context) {
                    Widget visualizerWidget;
                    if (visualizerStyle == VisualizerStyle.vinyl) {
                      visualizerWidget = VinylVisualizer(
                        imageUrl: track.imageUrl,
                        isPlaying: playerState.isPlaying,
                      );
                    } else if (visualizerStyle == VisualizerStyle.ambient) {
                      visualizerWidget = AmbientVisualizer(
                        imageUrl: track.imageUrl,
                        isPlaying: playerState.isPlaying,
                      );
                    } else {
                      // Classic Breathing Art
                      visualizerWidget = Center(
                        child: ScaleTransition(
                          scale: _breathAnim,
                          child: Hero(
                            tag: 'album_art_${track.id}',
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(alpha: 0.15),
                                      blurRadius: 40,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: CachedNetworkImage(
                                  imageUrl: track.imageUrl,
                                  fit: BoxFit.cover,
                                  width: 280,
                                  height: 280,
                                  placeholder: (_, __) => const ShimmerBox(
                                      width: 280, height: 280),
                                  errorWidget: (_, __, ___) => ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.asset(
                                      'assets/images/app_icon.png',
                                      width: 280,
                                      height: 280,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    if (playerState.isBuffering) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 0.6,
                            child: visualizerWidget,
                          ),
                          // Glassmorphic loading bubble
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(AppColors.accent),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Resolving Stream...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return visualizerWidget;
                  }
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Track Info ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title,
                            style: AppTextStyles.headline2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(track.artist,
                                  style: AppTextStyles.trackArtist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            SourceBadge(source: track.source),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Consumer(builder: (_, ref, __) {
                    final isFav = ref.watch(libraryProvider.select(
                        (s) => s.favorites.any((t) => t.id == track.id)));
                    return IconButton(
                      icon: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.like : AppColors.textHint,
                        size: 28,
                      ),
                      onPressed: () => ref
                          .read(libraryProvider.notifier)
                          .toggleFavorite(track),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Seek Bar (Gradient / Waveform) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: StreamBuilder<Duration>(
                stream: handler.positionStream,
                builder: (_, posSnap) {
                  return StreamBuilder<Duration?>(
                    stream: handler.durationStream,
                    builder: (_, durSnap) {
                      final position = posSnap.data ?? Duration.zero;
                      final duration = durSnap.data ?? Duration.zero;
                      final progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds /
                              duration.inMilliseconds
                          : 0.0;

                      if (visualizerStyle == VisualizerStyle.vinyl) {
                        return Column(
                          children: [
                            WaveformSeeker(
                              position: position,
                              duration: duration,
                              trackTitle: track.title,
                              isPlaying: playerState.isPlaying,
                              onSeek: (newPos) => handler.seek(newPos),
                            ),
                            const SizedBox(height: 4),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.accent,
                                inactiveTrackColor:
                                    AppColors.textHint.withValues(alpha: 0.15),
                                thumbColor: AppColors.accent,
                                overlayColor:
                                    AppColors.accent.withValues(alpha: 0.1),
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 4),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 8),
                              ),
                              child: Slider(
                                value: progress.clamp(0.0, 1.0),
                                onChanged: (v) {
                                  final newPos = Duration(
                                      milliseconds:
                                          (v * duration.inMilliseconds)
                                              .round());
                                  handler.seek(newPos);
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(formatDuration(position),
                                      style: AppTextStyles.caption),
                                  Text(formatDuration(duration),
                                      style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.accent,
                              inactiveTrackColor:
                                  AppColors.surfaceContainerHighest,
                              thumbColor: AppColors.accent,
                              overlayColor:
                                  AppColors.accent.withValues(alpha: 0.15),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: (v) {
                                final newPos = Duration(
                                    milliseconds:
                                        (v * duration.inMilliseconds)
                                            .round());
                                handler.seek(newPos);
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formatDuration(position),
                                    style: AppTextStyles.caption),
                                Text(formatDuration(duration),
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ─── Controls ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.shuffle_rounded,
                        color: AppColors.textHint),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_previous_rounded,
                        color: AppColors.textPrimary, size: 36),
                    onPressed: () =>
                        ref.read(playerProvider.notifier).skipToPrev(),
                  ),
                  // ─── Play/Pause Button ───
                  GestureDetector(
                    onTap: () {
                      if (!playerState.isBuffering) {
                        ref.read(playerProvider.notifier).togglePlayPause();
                      }
                    },
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: playerState.isBuffering
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation(Colors.black),
                                ),
                              )
                            : Icon(
                                playerState.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                key: ValueKey(playerState.isPlaying),
                                color: Colors.black,
                                size: 34,
                              ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next_rounded,
                        color: AppColors.textPrimary, size: 36),
                    onPressed: () =>
                        ref.read(playerProvider.notifier).skipToNext(),
                  ),
                  IconButton(
                    icon: Icon(Icons.repeat_rounded,
                        color: AppColors.textHint),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
