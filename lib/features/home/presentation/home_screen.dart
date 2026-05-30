import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer_track_tile.dart';
import '../../../shared/widgets/track_tile.dart';
import '../../../shared/models/track_model.dart';
import '../domain/home_provider.dart';
import '../domain/notifications_provider.dart';
import '../../player/domain/player_provider.dart';
import '../../mood/domain/mood_provider.dart';
import '../../library/domain/library_provider.dart';
import '../../search/domain/search_provider.dart';



class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    if (mounted) setState(() => _userName = name);
  }

  @override
  void dispose() {
    super.dispose();
  }





  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (_, scrollCtrl) {
                final themeItems = [
                  {
                    'mode': AppThemeMode.seoulNight,
                    'name': 'Seoul Night',
                    'desc': 'Warm Han River neon glow',
                    'bg': const Color(0xFF0D1020),
                    'accent': const Color(0xFFE48BA7),
                    'isDark': true
                  },
                  {
                    'mode': AppThemeMode.cherryBlossom,
                    'name': 'Cherry Blossom',
                    'desc': 'Soft spring flowers & cream',
                    'bg': const Color(0xFFF7F4F1),
                    'accent': const Color(0xFFD9AAA2),
                    'isDark': false
                  },
                  {
                    'mode': AppThemeMode.hanokSerenity,
                    'name': 'Hanok Serenity',
                    'desc': 'Slow traditional tea house wood',
                    'bg': const Color(0xFFF4EFEA),
                    'accent': const Color(0xFFA78B71),
                    'isDark': false
                  },
                  {
                    'mode': AppThemeMode.cloudMorning,
                    'name': 'Cloud Morning',
                    'desc': 'Misty morning mountain fog',
                    'bg': const Color(0xFFECEFF1),
                    'accent': const Color(0xFF78909C),
                    'isDark': false
                  },
                  {
                    'mode': AppThemeMode.midnightInk,
                    'name': 'Midnight Ink',
                    'desc': 'Classic dynamic brush painting',
                    'bg': const Color(0xFF121212),
                    'accent': const Color(0xFFFFFFFF),
                    'isDark': true
                  },
                ];

                return SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.divider.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Theme Studio', style: AppTextStyles.headline2),
                      const SizedBox(height: 4),
                      Text('Select a luxury Korean-inspired aesthetic',
                          style: AppTextStyles.trackArtist),
                      const SizedBox(height: 24),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: themeItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = themeItems[index];
                          final mode = item['mode'] as AppThemeMode;
                          final isSelected = ref.watch(themeProvider) == mode;
                          final cardBg = item['bg'] as Color;
                          final accent = item['accent'] as Color;
                          final isDark = item['isDark'] as bool;

                          return GestureDetector(
                            onTap: () {
                              ref.read(themeProvider.notifier).setTheme(mode);
                              setSheetState(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? accent
                                      : AppColors.divider.withValues(alpha: 0.15),
                                  width: isSelected ? 2.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                  if (isSelected)
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.12),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.spa_rounded,
                                        color: accent,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] as String,
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFFF7F3F0)
                                                : const Color(0xFF2A2523),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item['desc'] as String,
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFFF7F3F0)
                                                    .withValues(alpha: 0.6)
                                                : const Color(0xFF2A2523)
                                                    .withValues(alpha: 0.6),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: isDark
                                            ? const Color(0xFF0D1020)
                                            : Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _NotificationPanel();
      },
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final selectedLang = ref.watch(selectedLanguageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── 1. Luxury Editorial Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'RaagaFlow 🌸',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Pretendard',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const Spacer(),
                        // Theme Switcher Button
                        GestureDetector(
                          onTap: _showThemePicker,
                          child: Icon(
                            Icons.palette_outlined,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Notification Bell
                        Consumer(builder: (context, ref, _) {
                          final notifState = ref.watch(notificationsProvider);
                          final hasUnread = notifState.list.any((n) => n.isNew);
                          return GestureDetector(
                            onTap: _showNotificationPanel,
                            child: Stack(
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppColors.textPrimary,
                                  size: 24,
                                ),
                                if (hasUnread)
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(width: 16),
                        // Circle Portrait Avatar
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          backgroundImage: const AssetImage(
                            'assets/images/app_icon.png',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _userName.isNotEmpty
                          ? '$_greeting, $_userName 🌸'
                          : '$_greeting 🌸',
                      style: AppTextStyles.headline2.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Let the music heal your soul.',
                      style: AppTextStyles.trackArtist.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── 2. Hero Playing Now Card ───
            SliverToBoxAdapter(
              child: Consumer(builder: (context, ref, child) {
                final playerState = ref.watch(playerProvider);
                final track = playerState.currentTrack;
                final isPlaying = playerState.isPlaying;

                final trendingAsync = ref.watch(trendingProvider(selectedLang));
                final suggestedTrack = trendingAsync.value?.firstOrNull;

                if (track == null && trendingAsync.isLoading) {
                  return const ShimmerHeroCard();
                }

                final displayTrack = track ?? suggestedTrack;
                
                final imageUrl = displayTrack?.imageUrl ?? '';
                final title = displayTrack?.title ?? 'Loading...';
                final artist = displayTrack?.artist ?? '';

                return GestureDetector(
                  onTap: () {
                    if (track != null) {
                      context.push('/player');
                    } else if (suggestedTrack != null) {
                      ref.read(playerProvider.notifier).play(suggestedTrack, queue: trendingAsync.value ?? []);
                      context.push('/player');
                    }
                  },
                  child: Container(
                    height: 200,
                    margin: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : const DecorationImage(
                              image: AssetImage('assets/images/app_icon.png'),
                              fit: BoxFit.cover,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.black.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          Text(
                            track != null ? 'PLAYING NOW' : 'SUGGESTED',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            artist,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (track != null) {
                                    ref.read(playerProvider.notifier).togglePlayPause();
                                  } else if (suggestedTrack != null) {
                                    ref.read(playerProvider.notifier).play(suggestedTrack, queue: trendingAsync.value ?? []);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Page Indicators
                              Row(
                                children: List.generate(4, (index) {
                                  return Container(
                                    width: index == 0 ? 12 : 5,
                                    height: 5,
                                    margin: const EdgeInsets.only(left: 4),
                                    decoration: BoxDecoration(
                                      color: index == 0
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            // ─── 3. Continue Listening Section ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    Text('Continue Listening', style: AppTextStyles.sectionTitle),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.go('/library'),
                      child: Text(
                        'View all >',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 206,
                child: Consumer(builder: (context, ref, _) {
                  final history = ref.watch(libraryProvider.select((s) => s.history));
                  if (history.isNotEmpty) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: history.length,
                      itemBuilder: (context, i) {
                        return _buildListeningCard(context, ref, history[i], history);
                      },
                    );
                  }
                  // Fallback: show trending in user's primary language
                  final trendingAsync = ref.watch(trendingProvider(selectedLang));
                  return trendingAsync.when(
                    loading: () => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: 4,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 140, height: 140, radius: 16),
                            const SizedBox(height: 8),
                            ShimmerBox(width: 100, height: 12, radius: 6),
                            const SizedBox(height: 5),
                            ShimmerBox(width: 70, height: 10, radius: 6),
                          ],
                        ),
                      ),
                    ),
                    error: (e, _) => const Center(child: Text('Could not load songs')),
                    data: (tracks) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: tracks.length,
                        itemBuilder: (context, i) {
                          return _buildListeningCard(context, ref, tracks[i], tracks);
                        },
                      );
                    },
                  );
                }),
              ),
            ),

            // ─── 3b. Newly Added Section ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    Text('Newly Added', style: AppTextStyles.sectionTitle),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/newly-added'),
                      child: Text(
                        'View all >',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 206,
                child: Consumer(builder: (context, ref, _) {
                  final newReleasesAsync = ref.watch(combinedNewReleasesProvider);
                  return newReleasesAsync.when(
                    loading: () => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: 5,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 130, height: 130, radius: 20),
                            const SizedBox(height: 8),
                            ShimmerBox(width: 100, height: 12, radius: 6),
                            const SizedBox(height: 5),
                            ShimmerBox(width: 70, height: 10, radius: 6),
                          ],
                        ),
                      ),
                    ),
                    error: (e, _) => const Center(child: Text('Could not load new releases')),
                    data: (tracks) {
                      if (tracks.isEmpty) {
                        return const Center(child: Text('No new releases found'));
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: tracks.length,
                        itemBuilder: (context, i) {
                          return _buildListeningCard(context, ref, tracks[i], tracks);
                        },
                      );
                    },
                  );
                }),
              ),
            ),

            // ─── 4. Mood Collections Section ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    Text('Mood Collections', style: AppTextStyles.sectionTitle),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/mood'),
                      child: Text(
                        'View all >',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _buildMoodCard(
                      context, ref,
                      'Rainy Evening',
                      '32 tracks',
                      Icons.cloudy_snowing,
                      const Color(0xFF1E293B),
                      'https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?auto=format&fit=crop&w=400&q=80',
                    ),
                    _buildMoodCard(
                      context, ref,
                      'Late Night Drive',
                      '24 tracks',
                      Icons.directions_car_rounded,
                      const Color(0xFF2E1065),
                      'https://images.unsplash.com/photo-1494959764136-6be9eb3c261e?auto=format&fit=crop&w=400&q=80',
                    ),
                    _buildMoodCard(
                      context, ref,
                      'Workout Grind',
                      '45 tracks',
                      Icons.fitness_center_rounded,
                      const Color(0xFF7C2D12),
                      'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=400&q=80',
                    ),
                    _buildMoodCard(
                      context, ref,
                      'Deep Focus',
                      '50 tracks',
                      Icons.psychology_rounded,
                      const Color(0xFF064E3B),
                      'https://images.unsplash.com/photo-1488190211105-8b0e65b80b4e?auto=format&fit=crop&w=400&q=80',
                    ),
                  ],
                ),
              ),
            ),

            // ─── 5. Per-Language Trending Sections ───
            Consumer(builder: (context, ref, _) {
              final langsAsync = ref.watch(selectedLanguagesProvider);
              return langsAsync.when(
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (languages) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lang = languages[index];
                        final label = lang[0].toUpperCase() + lang.substring(1);
                        return _LanguageTrendingSection(
                          language: lang,
                          label: label,
                        );
                      },
                      childCount: languages.length,
                    ),
                  );
                },
              );
            }),

            // ─── 6. Recently Played Section ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: Row(
                  children: [
                    Text('Recently Played', style: AppTextStyles.sectionTitle),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.go('/library'),
                      child: Text(
                        'View all >',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Consumer(builder: (context, ref, _) {
              final history = ref.watch(libraryProvider.select((s) => s.history));
              if (history.isNotEmpty) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i >= history.length) return const SizedBox.shrink();
                      return TrackTile(track: history[i], queue: history);
                    },
                    childCount: history.length > 3 ? 3 : history.length,
                  ),
                );
              }
              // Fallback: show trending in user's primary language
              final trendingAsync = ref.watch(trendingProvider(selectedLang));
              return trendingAsync.when(
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ShimmerTrackTile(),
                    childCount: 3,
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: ErrorView(
                    message: 'Could not load songs',
                    onRetry: () => ref.invalidate(trendingProvider(selectedLang)),
                  ),
                ),
                data: (tracks) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i >= tracks.length) return const SizedBox.shrink();
                      return TrackTile(track: tracks[i], queue: tracks);
                    },
                    childCount: tracks.length > 3 ? 3 : tracks.length,
                  ),
                ),
              );
            }),
            const SliverToBoxAdapter(child: SizedBox(height: 180)),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningCard(BuildContext context, WidgetRef ref, TrackModel track, List<TrackModel> queue) {
    return GestureDetector(
      onTap: () {
        ref.read(playerProvider.notifier).play(track, queue: queue);
        context.push('/player');
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    track.imageUrl,
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/app_icon.png',
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Hover Play Button Overlay
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCard(BuildContext context, WidgetRef ref, String title, String subtitle, IconData icon, Color color, String imageUrl) {
    return GestureDetector(
      onTap: () {
        ref.read(moodProvider.notifier).generatePlaylist(title);
        context.push('/mood');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.45),
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Premium Notification Panel ───────────────────────────────────────────────

class _NotificationPanel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<_NotificationPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationsProvider);
    final notifications = notifState.list;
    final unreadCount = notifications.where((n) => n.isNew).length;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: DraggableScrollableSheet(
          initialChildSize: 0.72,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle bar ──
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 20, 4),
                    child: Row(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notifications',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Pretendard',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  unreadCount > 0 ? '$unreadCount new updates' : 'All caught up!',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (unreadCount > 0)
                          GestureDetector(
                            onTap: () {
                              ref.read(notificationsProvider.notifier).markAllAsRead();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Mark all read',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Notification List ──
                  Expanded(
                    child: notifState.isLoading && notifications.isEmpty
                        ? ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: 4,
                            itemBuilder: (_, __) => const ShimmerTrackTile(),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: notifications.length,
                            itemBuilder: (_, i) {
                              final notif = notifications[i];
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: notif.isNew
                                      ? notif.bgColor
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: notif.isNew
                                        ? notif.iconColor.withValues(alpha: 0.3)
                                        : AppColors.divider.withValues(alpha: 0.08),
                                    width: notif.isNew ? 1.2 : 0.8,
                                  ),
                                  boxShadow: notif.isNew
                                      ? [
                                          BoxShadow(
                                            color: notif.iconColor.withValues(alpha: 0.08),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      // Mark read
                                      ref.read(notificationsProvider.notifier).markAsRead(notif.id);
                                      
                                      // If it has a track associated, play it and dismiss sheet!
                                      if (notif.track != null) {
                                        ref.read(playerProvider.notifier).play(notif.track!);
                                        Navigator.pop(context); // Close notifications panel
                                        context.push('/player'); // Open player
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: notif.iconColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              notif.icon,
                                              color: notif.iconColor,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notif.title,
                                                        style: TextStyle(
                                                          color: AppColors.textPrimary,
                                                          fontSize: 13,
                                                          fontWeight: notif.isNew
                                                              ? FontWeight.w700
                                                              : FontWeight.w600,
                                                          letterSpacing: -0.2,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (notif.isNew)
                                                      Container(
                                                        width: 7,
                                                        height: 7,
                                                        margin: const EdgeInsets.only(left: 6),
                                                        decoration: BoxDecoration(
                                                          color: notif.iconColor,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  notif.subtitle,
                                                  style: TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  notif.time,
                                                  style: TextStyle(
                                                    color: AppColors.textHint,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Premium Suggested/Hero Shimmer Card ───

class ShimmerHeroCard extends StatelessWidget {
  const ShimmerHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceContainerHigh,
      child: Container(
        height: 200,
        margin: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 8),
            Container(width: 180, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 6),
            Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const Spacer(),
                Row(
                  children: List.generate(4, (index) {
                    return Container(
                      width: index == 0 ? 12 : 5,
                      height: 5,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-Language Trending Section Widget
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageTrendingSection extends ConsumerWidget {
  final String language;
  final String label;

  const _LanguageTrendingSection({
    required this.language,
    required this.label,
  });

  // Language-specific emoji flags/icons for a premium feel
  static const _langEmoji = {
    'hindi':      '🎵',
    'tamil':      '🎶',
    'telugu':     '🎸',
    'kannada':    '🥁',
    'malayalam':  '🎷',
    'punjabi':    '🎺',
    'bengali':    '🪗',
    'marathi':    '🎻',
    'gujarati':   '🪘',
    'bhojpuri':   '🎙️',
    'haryanvi':   '🎤',
    'rajasthani': '🪕',
    'odia':       '🎵',
    'english':    '🌍',
    'urdu':       '🌙',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingProvider(language));
    final emoji = _langEmoji[language] ?? '🎵';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          child: Row(
            children: [
              // Coloured language pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$label Trending',
                style: AppTextStyles.sectionTitle,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ref.read(searchProvider.notifier).search('latest $language songs');
                  context.go('/search');
                },
                child: Text(
                  'View all >',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Cards Row ──
        SizedBox(
          height: 206,
          child: trendingAsync.when(
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 5,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 130, height: 130, radius: 20),
                    const SizedBox(height: 8),
                    ShimmerBox(width: 100, height: 10, radius: 6),
                    const SizedBox(height: 5),
                    ShimmerBox(width: 70, height: 8, radius: 6),
                  ],
                ),
              ),
            ),
            error: (_, __) => Center(
              child: Text(
                'Could not load $label tracks',
                style: TextStyle(color: AppColors.textHint, fontSize: 13),
              ),
            ),
            data: (tracks) => ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: tracks.length,
              itemBuilder: (context, i) {
                final track = tracks[i];
                return GestureDetector(
                  onTap: () {
                    ref.read(playerProvider.notifier).play(track, queue: tracks);
                    context.push('/player');
                  },
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                track.imageUrl,
                                width: 130,
                                height: 130,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Play overlay
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artist,
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

