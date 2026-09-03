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
import '../../downloads/domain/download_provider.dart';
import '../domain/player_provider.dart';
import '../../../shared/models/download_model.dart';
import 'widgets/ambient_visualizer.dart';
import 'widgets/vinyl_visualizer.dart';
import 'widgets/audio_effects_panel.dart';
import 'widgets/spatial_audio_sheet.dart';
import 'widgets/sleep_timer_sheet.dart';
import 'widgets/queue_sheet.dart';
import '../domain/spatial_audio_provider.dart';
import '../domain/dynamic_palette_provider.dart';
import '../domain/sleep_timer_provider.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _breathAnim = Tween<double>(begin: 0.985, end: 1.015).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  void _showVisualizerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final currentStyle = ref.watch(visualizerProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.motion_photos_on_rounded, color: AppColors.accent, size: 22),
                        const SizedBox(width: 10),
                        Text('Visualizer Studio', style: AppTextStyles.headline2),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _visualizerTile(
                      ctx,
                      ref,
                      style: VisualizerStyle.classic,
                      current: currentStyle,
                      icon: Icons.image_rounded,
                      title: 'Classic Artwork',
                      desc: 'Breathing high-res album cover with dynamic ambient aura',
                    ),
                    const SizedBox(height: 8),
                    _visualizerTile(
                      ctx,
                      ref,
                      style: VisualizerStyle.vinyl,
                      current: currentStyle,
                      icon: Icons.album_rounded,
                      title: 'Vinyl Turntable',
                      desc: 'Realistic spinning vinyl disc with tonearm and groove reflections',
                    ),
                    const SizedBox(height: 8),
                    _visualizerTile(
                      ctx,
                      ref,
                      style: VisualizerStyle.ambient,
                      current: currentStyle,
                      icon: Icons.blur_on_rounded,
                      title: 'Ambient Gyroscope Orbits',
                      desc: '3D holographic orbiting rings with glowing satellite particles',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _visualizerTile(
    BuildContext context,
    WidgetRef ref, {
    required VisualizerStyle style,
    required VisualizerStyle current,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final isSelected = style == current;
    return GestureDetector(
      onTap: () {
        ref.read(visualizerProvider.notifier).setStyle(style);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.14)
              : AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.divider.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : AppColors.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
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
    final palette = ref.watch(dynamicPaletteProvider);
    final sleepTimerState = ref.watch(sleepTimerProvider);
    final spatial = ref.watch(spatialAudioProvider);

    // Sync breathing scale with playback state smoothly
    if (playerState.isPlaying) {
      if (!_breathCtrl.isAnimating) {
        _breathCtrl.repeat(reverse: true);
      }
    } else {
      if (_breathCtrl.isAnimating) {
        _breathCtrl.stop();
      }
    }

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: Text('Nothing playing',
                style: TextStyle(color: AppColors.textHint))),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.backgroundGradientTop,
                palette.backgroundGradientBottom,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: true,
            child: Column(
              children: [
              // ─── 1. Luxury Header Bar ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Glass circular back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'NOW PLAYING',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: palette.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.graphic_eq_rounded,
                                  color: Colors.white.withValues(alpha: 0.6), size: 10),
                              const SizedBox(width: 4),
                              Text(
                                'HD AUDIO · AAC',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action Pill: Visualizer + Sleep Timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Visualizer Picker Button
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              visualizerStyle == VisualizerStyle.vinyl
                                  ? Icons.album_rounded
                                  : (visualizerStyle == VisualizerStyle.ambient
                                      ? Icons.blur_on_rounded
                                      : Icons.motion_photos_on_rounded),
                              color: palette.accent,
                              size: 20,
                            ),
                            tooltip: 'Visualizer: ${visualizerStyle.name.toUpperCase()}',
                            onPressed: () => _showVisualizerPicker(context),
                          ),
                          // Sleep Timer Button
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                            icon: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Icon(
                                  sleepTimerState.isActive
                                      ? Icons.bedtime_rounded
                                      : Icons.bedtime_outlined,
                                  color: sleepTimerState.isActive
                                      ? palette.accent
                                      : Colors.white.withValues(alpha: 0.85),
                                  size: 20,
                                ),
                                if (sleepTimerState.isActive)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: palette.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            tooltip: sleepTimerState.isActive
                                ? 'Sleep Timer: ${sleepTimerState.formattedRemaining}'
                                : 'Set Sleep Timer',
                            onPressed: () => SleepTimerSheet.show(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── 2. Centerpiece Visualizer / Artwork Stage ───
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RepaintBoundary(
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
                          // Classic Breathing Art with 3D Depth
                          visualizerWidget = Center(
                            child: ScaleTransition(
                              scale: _breathAnim,
                            child: Hero(
                              tag: 'album_art_${track.id}',
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    // Colored ambient aura
                                    BoxShadow(
                                      color: palette.accent.withValues(alpha: 0.38),
                                      blurRadius: 44,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 10),
                                    ),
                                    // Deep shadow
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      blurRadius: 36,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(27),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CachedNetworkImage(
                                          imageUrl: track.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const ShimmerBox(
                                              width: 280, height: 280, radius: 28),
                                          errorWidget: (_, __, ___) => ClipRRect(
                                            borderRadius: BorderRadius.circular(28),
                                            child: Image.asset(
                                              'assets/images/app_icon.png',
                                              width: 280,
                                              height: 280,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Glass sheen overlay
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white.withValues(alpha: 0.14),
                                                Colors.transparent,
                                                Colors.black.withValues(alpha: 0.15),
                                              ],
                                              stops: const [0.0, 0.45, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                              opacity: 0.55,
                              child: visualizerWidget,
                            ),
                            // Glassmorphic loading pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14161F).withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: palette.accent.withValues(alpha: 0.45),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(palette.accent),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Buffering Audio...',
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
                          ],
                        );
                      }

                      return visualizerWidget;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

              // ─── 3. Track Title, Artist & Action Pill ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Track Title & Artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  track.artist,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SourceBadge(source: track.source),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Glass Action Pill: Download + Heart
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Download Action
                          Consumer(builder: (_, ref, __) {
                            final downloadState = ref.watch(downloadProvider);
                            final isDownloaded = downloadState.downloads.any((d) => d.songId == track.id);
                            final queueItem = downloadState.queue.cast<DownloadQueueItem?>().firstWhere(
                                  (q) => q?.track.id == track.id,
                                  orElse: () => null,
                                );
                            final isDownloading = queueItem?.status == DownloadStatus.downloading;
                            final progress = queueItem?.progress ?? 0.0;

                            if (isDownloaded) {
                              return IconButton(
                                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.check_circle_rounded, color: palette.accent, size: 22),
                                tooltip: 'Available Offline',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"${track.title}" is saved for offline playback.'),
                                      backgroundColor: AppColors.surfaceContainerHigh,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                              );
                            } else if (isDownloading) {
                              return Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: progress > 0 ? progress : null,
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation(palette.accent),
                                      ),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: TextStyle(
                                          color: palette.accent,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return IconButton(
                              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.download_for_offline_outlined, color: Colors.white.withValues(alpha: 0.85), size: 22),
                              tooltip: 'Download Song',
                              onPressed: () {
                                ref.read(downloadProvider.notifier).downloadTrack(track);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Downloading "${track.title}"...'),
                                    backgroundColor: AppColors.surfaceContainerHigh,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                            );
                          }),
                          // Favorite / Heart Action
                          Consumer(builder: (_, ref, __) {
                            final isFav = ref.watch(libraryProvider.select(
                                (s) => s.favorites.any((t) => t.id == track.id)));
                            return IconButton(
                              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? AppColors.like : Colors.white.withValues(alpha: 0.85),
                                size: 22,
                              ),
                              onPressed: () => ref
                                  .read(libraryProvider.notifier)
                                  .toggleFavorite(track),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── 4. Fluid Capsule Scrubber / Seek Bar ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<Duration>(
                  stream: handler.positionStream,
                  builder: (_, posSnap) {
                    return StreamBuilder<Duration?>(
                      stream: handler.durationStream,
                      builder: (_, durSnap) {
                        final position = posSnap.data ?? Duration.zero;
                        final duration = durSnap.data ?? Duration.zero;
                        final currentPos = _dragValue != null
                            ? Duration(milliseconds: (_dragValue! * (duration.inMilliseconds > 0 ? duration.inMilliseconds : 1)).round())
                            : position;
                        final progress = duration.inMilliseconds > 0
                            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0;

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: palette.accent,
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                                thumbColor: Colors.white,
                                overlayColor: palette.accent.withValues(alpha: 0.2),
                                trackHeight: 3.5,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                  elevation: 4,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                              ),
                              child: Slider(
                                value: _dragValue ?? progress,
                                onChangeStart: (v) => setState(() => _dragValue = v),
                                onChanged: (v) => setState(() => _dragValue = v),
                                onChangeEnd: (v) {
                                  final newPos = Duration(
                                    milliseconds: (v * duration.inMilliseconds).round(),
                                  );
                                  handler.seek(newPos);
                                  setState(() => _dragValue = null);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatDuration(currentPos),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  Text(
                                    formatDuration(duration),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
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
              const SizedBox(height: 10),

              // ─── 5. Master Playback Deck ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: playerState.isShuffle ? palette.accent : Colors.white.withValues(alpha: 0.4),
                        size: 24,
                      ),
                      onPressed: () => ref.read(playerProvider.notifier).toggleShuffle(),
                    ),
                    // Skip Previous
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      onPressed: () => ref.read(playerProvider.notifier).skipToPrev(),
                    ),
                    // Hero Master Play/Pause Button
                    GestureDetector(
                      onTap: () {
                        if (!playerState.isBuffering) {
                          ref.read(playerProvider.notifier).togglePlayPause();
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              palette.accent,
                              Color.alphaBlend(Colors.white.withValues(alpha: 0.22), palette.accent),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: palette.accent.withValues(alpha: 0.45),
                              blurRadius: 26,
                              spreadRadius: 2,
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
                                  size: 36,
                                ),
                        ),
                      ),
                    ),
                    // Skip Next
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      onPressed: () => ref.read(playerProvider.notifier).skipToNext(),
                    ),
                    // Repeat / Loop
                    IconButton(
                      icon: Icon(
                        playerState.isRepeat ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                        color: playerState.isRepeat ? palette.accent : Colors.white.withValues(alpha: 0.4),
                        size: 24,
                      ),
                      onPressed: () => ref.read(playerProvider.notifier).toggleRepeat(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── 6. Integrated Bottom Studio Dock (Glass Capsule) ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14161F).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 8D Spatial Audio Capsule Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              useRootNavigator: true,
                              backgroundColor: Colors.transparent,
                              barrierColor: Colors.black.withValues(alpha: 0.75),
                              isScrollControlled: true,
                              builder: (context) => const SpatialAudioSheet(),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: spatial.isEnabled
                                  ? palette.accent
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.spatial_audio_rounded,
                                  color: spatial.isEnabled ? Colors.black : palette.accent,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    spatial.isEnabled
                                        ? spatial.activePreset.displayName
                                        : '8D Spatial Audio',
                                    style: TextStyle(
                                      color: spatial.isEnabled ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // DSP & Equalizer Button
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            backgroundColor: Colors.transparent,
                            barrierColor: Colors.black.withValues(alpha: 0.75),
                            isScrollControlled: true,
                            builder: (context) => const AudioEffectsPanel(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.graphic_eq_rounded, color: palette.accent, size: 18),
                              const SizedBox(width: 6),
                              const Text(
                                'DSP & EQ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Queue Drawer Trigger
                      GestureDetector(
                        onTap: () => QueueSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.queue_music_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}
}
