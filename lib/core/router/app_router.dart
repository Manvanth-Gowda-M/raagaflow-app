import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/newly_added_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/mood/presentation/mood_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/player/presentation/full_player_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/themes/presentation/themes_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/player/presentation/widgets/mini_player.dart';
import '../../features/player/domain/player_provider.dart';
import '../../shared/models/track_model.dart';
import '../../shared/services/web_notification_service.dart';
import '../theme/app_colors.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _toastCtrl;
  late final Animation<Offset> _toastSlide;
  TrackModel? _activeTrack;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _toastCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _toastSlide = Tween<Offset>(
      begin: const Offset(0, -1.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _toastCtrl,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _toastCtrl.dispose();
    super.dispose();
  }

  void _triggerToast(TrackModel track) {
    setState(() {
      _activeTrack = track;
      _isVisible = true;
    });
    _toastCtrl.forward();

    // Automatically dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _activeTrack?.id == track.id) {
        _toastCtrl.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isVisible = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    // Watch playerProvider changes to show custom Now Playing banner toasts & browser notifications reactively
    ref.listen<PlayerState>(playerProvider, (previous, next) {
      if (next.currentTrack != null && next.isPlaying) {
        final trackChanged = next.currentTrack?.id != previous?.currentTrack?.id;
        final becamePlaying = previous == null || !previous.isPlaying;
        if (trackChanged || becamePlaying) {
          _triggerToast(next.currentTrack!);
          
          // Trigger a premium HTML5 desktop notification popup for Web browser platform
          WebNotificationService.showTrackNotification(
            title: next.currentTrack!.title,
            artist: next.currentTrack!.artist,
            imageUrl: next.currentTrack!.imageUrl,
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.navigationShell,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 108, // Floats cleanly above the new floating navigation bar
            child: const MiniPlayer(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PremiumNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                );
              },
            ),
          ),
          // ─── Branded Floating In-App Now Playing Notification Toast ───
          if (_isVisible && _activeTrack != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: _toastSlide,
                child: GestureDetector(
                  onTap: () {
                    _toastCtrl.reverse().then((_) {
                      if (mounted) setState(() => _isVisible = false);
                    });
                    context.push('/player');
                  },
                  child: Container(
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: _activeTrack!.imageUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: AppColors.surfaceContainerHigh),
                                  errorWidget: (_, __, ___) => Image.asset(
                                    'assets/images/app_icon.png',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Now Playing 🎵',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _activeTrack!.title,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _activeTrack!.artist,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close_rounded, color: AppColors.textHint, size: 18),
                                onPressed: () {
                                  _toastCtrl.reverse().then((_) {
                                    if (mounted) setState(() => _isVisible = false);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PremiumNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final destinations = [
      {
        'iconActive': Icons.home_rounded,
        'iconInactive': Icons.home_outlined,
        'label': 'Home'
      },
      {
        'iconActive': Icons.search_rounded,
        'iconInactive': Icons.search_rounded,
        'label': 'Search'
      },
      {
        'iconActive': Icons.library_music_rounded,
        'iconInactive': Icons.library_music_outlined,
        'label': 'Library'
      },
      {
        'iconActive': Icons.palette_rounded,
        'iconInactive': Icons.palette_outlined,
        'label': 'Themes'
      },
      {
        'iconActive': Icons.person_rounded,
        'iconInactive': Icons.person_outline_rounded,
        'label': 'Profile'
      },
    ];

    return SafeArea(
      bottom: true,
      child: Container(
        height: 80,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8), // FLOATING ISLAND!
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.2),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(destinations.length, (index) {
            final isSelected = index == currentIndex;
            final dest = destinations[index];
            final icon = (isSelected ? dest['iconActive'] : dest['iconInactive']) as IconData;
            final label = dest['label'] as String;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? AppColors.accent : AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 280),
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.children.length, (i) {
      return AnimationController(
        vsync: this,
        duration: widget.duration,
        value: i == widget.index ? 1.0 : 0.0,
      );
    });
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _controllers[oldWidget.index].reverse();
      _controllers[widget.index].forward();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.children.length, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            final isOffstage = _controllers[i].value == 0.0 && i != widget.index;
            return Offstage(
              offstage: isOffstage,
              child: child,
            );
          },
          child: FadeTransition(
            opacity: _controllers[i],
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.015),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _controllers[i],
                curve: Curves.easeOutCubic,
              )),
              child: IgnorePointer(
                ignoring: i != widget.index,
                child: TickerMode(
                  enabled: i == widget.index || _controllers[i].isAnimating,
                  child: widget.children[i],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final isOnboarded = prefs.getBool('onboarding_complete') ?? false;
      final hasName = (prefs.getString('user_name') ?? '').isNotEmpty;
      // Show onboarding if not done yet, OR if name was never entered
      if ((!isOnboarded || !hasName) && state.fullPath != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AnimatedIndexedStack(
            index: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
                routes: [
                  GoRoute(
                    path: 'newly-added',
                    pageBuilder: (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const NewlyAddedScreen(),
                      transitionsBuilder: (_, animation, __, child) => SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'mood',
                    pageBuilder: (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const MoodScreen(),
                      transitionsBuilder: (_, animation, __, child) => SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const SearchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const LibraryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/themes',
                pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ThemesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/player',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const FullPlayerScreen(),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        ),
      ),
    ],
  );
}
