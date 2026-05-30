import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/track_tile.dart';
import '../domain/library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          bottom: TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textHint,
            tabs: [
              Tab(text: 'Favorites'),
              Tab(text: 'Recent'),
              Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FavoritesTab(),
            _HistoryTab(),
            _PlaylistsTab(),
          ],
        ),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(libraryProvider).favorites;
    if (favorites.isEmpty) {
      return const EmptyStateView(
          message: 'No liked songs yet.\nTap the heart on any track.',
          icon: Icons.favorite_border);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 180),
      itemCount: favorites.length,
      itemBuilder: (_, i) =>
          TrackTile(track: favorites[i], queue: favorites),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(libraryProvider).history;
    if (history.isEmpty) {
      return const EmptyStateView(
          message: 'No recently played songs.',
          icon: Icons.history);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 180),
      itemCount: history.length,
      itemBuilder: (_, i) =>
          TrackTile(track: history[i], queue: history),
    );
  }
}

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(libraryProvider).playlists;

    return Scaffold(
      body: playlists.isEmpty
          ? const EmptyStateView(
              message: 'No playlists yet.\nTap + to create one.',
              icon: Icons.playlist_add)
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 180),
              itemCount: playlists.length,
              itemBuilder: (_, i) {
                final pl = playlists[i];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.queue_music, color: AppColors.textPrimary),
                  ),
                  title: Text(pl.name, style: AppTextStyles.trackTitle),
                  subtitle: Text('${pl.tracks.length} songs',
                      style: AppTextStyles.caption),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          backgroundColor: AppColors.accent,
          onPressed: () => _showCreateSheet(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New Playlist', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Playlist name',
                hintStyle: TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    ref
                        .read(libraryProvider.notifier)
                        .createPlaylist(controller.text.trim());
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
