import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/debouncer.dart';
import '../../../shared/models/track_model.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer_track_tile.dart';
import '../../../shared/widgets/track_tile.dart';
import '../../downloads/domain/download_provider.dart';
import '../domain/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  List<TrackModel> _searchOffline(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    final downloads = ref.read(downloadProvider).downloads;
    return downloads
        .where((d) =>
            d.title.toLowerCase().contains(q) ||
            d.artist.toLowerCase().contains(q) ||
            (d.album?.toLowerCase().contains(q) ?? false))
        .map((d) => d.toTrack())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final downloadState = ref.watch(downloadProvider);
    final isOffline = !downloadState.isOnline;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.accentGradient.createShader(bounds),
                        child: Text(
                          isOffline ? 'Offline Search' : 'Search',
                          style: AppTextStyles.headline1.copyWith(color: Colors.white),
                        ),
                      ),
                      if (isOffline) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OFFLINE',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.surfaceContainerHigh,
                      border: Border.all(color: AppColors.divider, width: 0.5),
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: false,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: isOffline
                            ? 'Search downloaded songs...'
                            : 'Songs, artists, albums...',
                        hintStyle: TextStyle(color: AppColors.textHint),
                        prefixIcon: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.accentGradient.createShader(bounds),
                          child: const Icon(Icons.search_rounded, color: Colors.white),
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    color: AppColors.textHint, size: 20),
                                onPressed: () {
                                  _controller.clear();
                                  ref.read(searchProvider.notifier).clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      onChanged: (q) {
                        setState(() {});
                        if (!isOffline) {
                          _debouncer.run(() {
                            ref.read(searchProvider.notifier).search(q);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isOffline
                  ? _buildOfflineBody(_controller.text.trim())
                  : _buildBody(searchState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBody(String query) {
    if (query.isEmpty) {
      final downloads = ref.watch(downloadProvider).downloads;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.offline_pin_rounded, size: 56, color: AppColors.accent),
            const SizedBox(height: 16),
            Text('Offline Search', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            Text(
              '${downloads.length} downloaded songs ready to search',
              style: AppTextStyles.trackArtist,
            ),
          ],
        ),
      );
    }

    final results = _searchOffline(query);
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No downloaded songs match "$query"', style: AppTextStyles.trackArtist),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 180),
      itemCount: results.length,
      itemBuilder: (_, i) => TrackTile(
        track: results[i],
        queue: results,
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    if (state.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.accentGradient.createShader(bounds),
              child: const Icon(Icons.music_note_rounded,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('Discover Indian music', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            Text('Search for songs, artists, or albums',
                style: AppTextStyles.trackArtist),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'Kannada Lofi',
                'Arijit Singh',
                'AR Rahman',
                'Shreya Ghoshal',
                'Sid Sriram',
                'Anirudh',
                'Diljit Dosanjh',
                'Pritam',
              ]
                  .map((q) => GestureDetector(
                        onTap: () {
                          _controller.text = q;
                          ref.read(searchProvider.notifier).search(q);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.divider, width: 0.5),
                          ),
                          child: Text(q,
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }

    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 180),
        itemCount: 8,
        itemBuilder: (_, __) => const ShimmerTrackTile(),
      );
    }

    if (state.error != null) {
      return ErrorView(
        message: 'Search failed. Check your connection.',
        onRetry: () =>
            ref.read(searchProvider.notifier).search(state.query),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No results found', style: AppTextStyles.trackArtist),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 180),
      itemCount: state.results.length,
      itemBuilder: (_, i) => TrackTile(
        track: state.results[i],
        queue: state.results,
      ),
    );
  }
}
