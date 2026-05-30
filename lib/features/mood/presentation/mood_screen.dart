import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer_track_tile.dart';
import '../../../shared/widgets/track_tile.dart';
import '../domain/mood_provider.dart';
import '../../player/domain/player_provider.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final AnimationController _animCtrl;

  final List<Map<String, dynamic>> _chips = const [
    {'icon': Icons.water_drop_rounded, 'label': 'Sad', 'key': 'udaas',
     'colors': AppColors.sadGradient},
    {'icon': Icons.emoji_emotions_rounded, 'label': 'Happy', 'key': 'khush',
     'colors': AppColors.morningGradient},
    {'icon': Icons.fitness_center_rounded, 'label': 'Workout', 'key': 'gym',
     'colors': AppColors.gymGradient},
    {'icon': Icons.self_improvement_rounded, 'label': 'Devotional', 'key': 'bhakti',
     'colors': AppColors.bhaktiGradient},
    {'icon': Icons.directions_car_rounded, 'label': 'Drive', 'key': 'drive',
     'colors': AppColors.driveGradient},
    {'icon': Icons.nightlight_round, 'label': 'Sleep', 'key': 'neend',
     'colors': AppColors.sleepGradient},
    {'icon': Icons.favorite_rounded, 'label': 'Romance', 'key': 'pyaar',
     'colors': AppColors.romanticGradient},
    {'icon': Icons.celebration_rounded, 'label': 'Party', 'key': 'party',
     'colors': AppColors.partyGradient},
    {'icon': Icons.psychology_rounded, 'label': 'Focus', 'key': 'study',
     'colors': AppColors.focusGradient},
    {'icon': Icons.spa_rounded, 'label': 'Chill', 'key': 'chill',
     'colors': AppColors.chillGradient},
    {'icon': Icons.water_rounded, 'label': 'Rain', 'key': 'barish',
     'colors': AppColors.rainGradient},
    {'icon': Icons.wb_sunny_rounded, 'label': 'Morning', 'key': 'subah',
     'colors': AppColors.morningGradient},
  ];

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
    _controller.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _generate(String mood) {
    _controller.text = mood;
    ref.read(moodProvider.notifier).generatePlaylist(mood);
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animCtrl,
          child: CustomScrollView(
            slivers: [
              if (moodState.tracks.isEmpty && !moodState.isLoading)
                SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.premiumGradient.createShader(bounds),
                        child: Text("What's your vibe?",
                            style: AppTextStyles.headline1
                                .copyWith(color: Colors.white)),
                      ),
                      const SizedBox(height: 4),
                      Text('Type a mood or pick one below',
                          style: AppTextStyles.trackArtist),
                      const SizedBox(height: 16),
                      // ─── Search Field ───
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.surfaceContainerHigh,
                          border: Border.all(
                              color: AppColors.divider, width: 0.5),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                              color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'e.g. romantic, chill, workout...',
                            hintStyle: TextStyle(
                                color: AppColors.textHint),
                            prefixIcon: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.accentGradient
                                      .createShader(bounds),
                              child: const Icon(Icons.music_note_rounded,
                                  color: Colors.white),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          onSubmitted: _generate,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ─── Mood Chips ───
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: _chips.map((chip) {
                          final colors = chip['colors'] as List<Color>;
                          final isActive =
                              moodState.currentMood == chip['key'];
                          return GestureDetector(
                            onTap: () => _generate(chip['key'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? LinearGradient(colors: colors)
                                    : null,
                                color: isActive
                                    ? null
                                    : AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(24),
                                border: isActive
                                    ? null
                                    : Border.all(
                                        color: colors[0].withValues(alpha: 0.3),
                                        width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(chip['icon'] as IconData,
                                      size: 16,
                                      color: isActive
                                          ? Colors.white
                                          : colors[0]),
                                  const SizedBox(width: 6),
                                  Text(
                                    chip['label'] as String,
                                    style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      // ─── Generate Button ───
                      if (moodState.currentMood.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _generate(_controller.text),
                              icon: const Icon(Icons.auto_awesome_rounded,
                                  color: Colors.black, size: 20),
                              label: const Text('Generate Playlist',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 15)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(25)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (moodState.isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ShimmerTrackTile(),
                    childCount: 8,
                  ),
                )
              else if (moodState.error != null)
                SliverToBoxAdapter(
                  child: ErrorView(
                    message: 'Could not generate playlist',
                    onRetry: () => _generate(moodState.currentMood),
                  ),
                )
              else if (moodState.tracks.isNotEmpty) ...[
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
                                if (GoRouterState.of(context).uri.toString() == '/mood') {
                                  context.go('/');
                                } else {
                                  context.pop();
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${moodState.currentMood.toUpperCase()} MOOD',
                                style: AppTextStyles.headline1.copyWith(color: AppColors.textPrimary, fontSize: 24),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              '${moodState.tracks.length} songs',
                              style: AppTextStyles.sectionTitle,
                            ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Saved to your ${moodState.currentMood} collection!'),
                                backgroundColor: AppColors.surfaceContainerHigh,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            );
                          },
                          icon: Icon(Icons.bookmark_add_outlined, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            ref.read(playerProvider.notifier).play(moodState.tracks.first, queue: moodState.tracks);
                          },
                          icon: ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.accentGradient
                                    .createShader(bounds),
                            child: const Icon(Icons.play_circle_filled,
                                color: Colors.white, size: 22),
                          ),
                          label: Text('Play All',
                              style: TextStyle(color: AppColors.accent)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => TrackTile(
                      track: moodState.tracks[i],
                      queue: moodState.tracks,
                    ),
                    childCount: moodState.tracks.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 180)),
            ],
          ),
        ),
      ),
    );
  }
}
