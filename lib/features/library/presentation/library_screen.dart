import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/models/playlist_model.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/track_tile.dart';
import '../../downloads/domain/download_provider.dart';
import '../../player/domain/player_provider.dart';
import '../domain/library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text('Your Library', style: AppTextStyles.headline1),
          bottom: TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textHint,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Favorites'),
              Tab(text: 'Playlists'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FavoritesTab(),
            _PlaylistsTab(),
            _HistoryTab(),
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
    final downloadNotifier = ref.read(downloadProvider.notifier);

    if (favorites.isEmpty) {
      return const EmptyStateView(
        icon: Icons.favorite_border_rounded,
        title: 'No liked songs yet',
        subtitle: 'Tap the heart icon on any song to save it to your favorites.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              Text('${favorites.length} songs', style: AppTextStyles.caption),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  downloadNotifier.downloadTracks(favorites);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading ${favorites.length} favorite songs for offline listening...'),
                      backgroundColor: AppColors.surfaceContainerHigh,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 16, color: Colors.black),
                label: const Text('Download All', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 180),
            itemCount: favorites.length,
            itemBuilder: (_, i) => TrackTile(track: favorites[i], queue: favorites),
          ),
        ),
      ],
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
        icon: Icons.history_rounded,
        title: 'No recently played songs',
        subtitle: 'Songs you play will appear here for easy access.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 180),
      itemCount: history.length,
      itemBuilder: (_, i) => TrackTile(track: history[i], queue: history),
    );
  }
}

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  void _openPlaylistDetails(BuildContext context, WidgetRef ref, PlaylistModel playlist) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PlaylistDetailSheet(playlist: playlist),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(libraryProvider).playlists;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: playlists.isEmpty
          ? EmptyStateView(
              icon: Icons.playlist_add_rounded,
              title: 'No playlists yet',
              subtitle: 'Create playlists to organize your favorite tracks.',
              actionLabel: 'Create Playlist',
              onAction: () => _showCreateSheet(context, ref),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 180, top: 8),
              itemCount: playlists.length,
              itemBuilder: (_, i) {
                final pl = playlists[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.queue_music_rounded, color: AppColors.accent),
                    ),
                    title: Text(pl.name, style: AppTextStyles.trackTitle),
                    subtitle: Text('${pl.tracks.length} songs', style: AppTextStyles.caption),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () => _openPlaylistDetails(context, ref, pl),
                  ),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          onPressed: () => _showCreateSheet(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Create New Playlist', style: AppTextStyles.headline2),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Kannada Lofi Chill',
                hintStyle: TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    ref.read(libraryProvider.notifier).createPlaylist(controller.text.trim());
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistDetailSheet extends ConsumerStatefulWidget {
  final PlaylistModel playlist;
  const _PlaylistDetailSheet({required this.playlist});

  @override
  ConsumerState<_PlaylistDetailSheet> createState() => _PlaylistDetailSheetState();
}

class _PlaylistDetailSheetState extends ConsumerState<_PlaylistDetailSheet> {
  bool _isSelectionMode = false;
  final Set<String> _selectedSongIds = {};

  @override
  Widget build(BuildContext context) {
    final pl = widget.playlist;
    final downloadNotifier = ref.read(downloadProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.queue_music_rounded, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pl.name, style: AppTextStyles.headline2, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${pl.tracks.length} tracks', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  // Delete playlist button
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: AppColors.textHint),
                    tooltip: 'Delete Playlist',
                    onPressed: () {
                      ref.read(libraryProvider.notifier).deletePlaylist(pl.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Action buttons row: Play All & Download Playlist & Select
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (pl.tracks.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(playerProvider.notifier).play(pl.tracks.first, queue: pl.tracks);
                      },
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                      label: const Text('Play All', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        downloadNotifier.downloadPlaylist(pl);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading "${pl.name}" (${pl.tracks.length} songs) for offline listening...'),
                            backgroundColor: AppColors.surfaceContainerHigh,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: Icon(Icons.download_rounded, color: AppColors.accent, size: 18),
                      label: Text('Download Playlist', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (pl.tracks.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = !_isSelectionMode;
                          _selectedSongIds.clear();
                        });
                      },
                      child: Text(_isSelectionMode ? 'Done' : 'Select', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const Divider(height: 16),
            // Multi-selection bar
            if (_isSelectionMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                color: AppColors.surfaceContainerHigh,
                child: Row(
                  children: [
                    Text('${_selectedSongIds.length} selected', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedSongIds.length == pl.tracks.length) {
                            _selectedSongIds.clear();
                          } else {
                            _selectedSongIds.addAll(pl.tracks.map((t) => t.id));
                          }
                        });
                      },
                      child: Text(_selectedSongIds.length == pl.tracks.length ? 'Deselect All' : 'Select All', style: TextStyle(color: AppColors.accent)),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectedSongIds.isEmpty
                          ? null
                          : () {
                              final selectedTracks = pl.tracks.where((t) => _selectedSongIds.contains(t.id)).toList();
                              downloadNotifier.downloadTracks(selectedTracks);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Downloading ${selectedTracks.length} selected tracks...'),
                                  backgroundColor: AppColors.surfaceContainerHigh,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              setState(() {
                                _isSelectionMode = false;
                                _selectedSongIds.clear();
                              });
                            },
                      icon: const Icon(Icons.download_rounded, size: 14, color: Colors.black),
                      label: const Text('Download', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
            // Track list
            Expanded(
              child: pl.tracks.isEmpty
                  ? Center(child: Text('No tracks in this playlist yet.', style: TextStyle(color: AppColors.textHint)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: pl.tracks.length,
                      itemBuilder: (_, i) {
                        final track = pl.tracks[i];
                        final isSelected = _selectedSongIds.contains(track.id);
                        return TrackTile(
                          track: track,
                          queue: pl.tracks,
                          isSelectable: _isSelectionMode,
                          isSelected: isSelected,
                          onSelectChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedSongIds.add(track.id);
                              } else {
                                _selectedSongIds.remove(track.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

