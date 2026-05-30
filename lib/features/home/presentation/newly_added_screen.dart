import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer_track_tile.dart';
import '../../../shared/widgets/track_tile.dart';
import '../domain/home_provider.dart';
import '../../player/domain/player_provider.dart';

class NewlyAddedScreen extends ConsumerStatefulWidget {
  const NewlyAddedScreen({super.key});

  @override
  ConsumerState<NewlyAddedScreen> createState() => _NewlyAddedScreenState();
}

class _NewlyAddedScreenState extends ConsumerState<NewlyAddedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newReleasesAsync = ref.watch(combinedNewReleasesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animCtrl,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                            onPressed: () {
                              if (GoRouterState.of(context).uri.toString() == '/newly-added') {
                                context.go('/');
                              } else {
                                context.pop();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.premiumGradient.createShader(bounds),
                              child: Text(
                                'Newly Added 🎵',
                                style: AppTextStyles.headline1.copyWith(
                                  color: Colors.white,
                                  fontSize: 24,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 48),
                        child: Text(
                          'Fresh new music matching your preferred languages',
                          style: AppTextStyles.trackArtist.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      newReleasesAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (tracks) {
                          if (tracks.isEmpty) return const SizedBox.shrink();
                          return Row(
                            children: [
                              Text(
                                '${tracks.length} songs',
                                style: AppTextStyles.sectionTitle.copyWith(
                                  fontSize: 14,
                                  color: AppColors.textHint,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  ref.read(playerProvider.notifier).play(tracks.first, queue: tracks);
                                },
                                icon: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      AppColors.accentGradient
                                          .createShader(bounds),
                                  child: const Icon(Icons.play_circle_filled,
                                      color: Colors.white, size: 22),
                                ),
                                label: Text('Play All',
                                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              newReleasesAsync.when(
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ShimmerTrackTile(),
                    childCount: 8,
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: ErrorView(
                    message: 'Could not load newly added songs',
                    onRetry: () => ref.refresh(combinedNewReleasesProvider),
                  ),
                ),
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Text('No new releases found'),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => TrackTile(
                        track: tracks[i],
                        queue: tracks,
                      ),
                      childCount: tracks.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 180)),
            ],
          ),
        ),
      ),
    );
  }
}
