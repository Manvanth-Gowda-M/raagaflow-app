import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/models/download_model.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/track_tile.dart';
import '../../player/domain/player_provider.dart';
import '../domain/download_provider.dart';

enum DownloadSortOption {
  recent,
  largest,
  alphabetical,
}

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DownloadSortOption _sortOption = DownloadSortOption.recent;
  bool _isSelectionMode = false;
  final Set<String> _selectedSongIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  List<DownloadedSong> _getSortedAndFilteredDownloads(List<DownloadedSong> downloads) {
    var list = downloads.where((d) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return d.title.toLowerCase().contains(q) ||
          d.artist.toLowerCase().contains(q) ||
          (d.album?.toLowerCase().contains(q) ?? false);
    }).toList();

    switch (_sortOption) {
      case DownloadSortOption.recent:
        list.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
        break;
      case DownloadSortOption.largest:
        list.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
        break;
      case DownloadSortOption.alphabetical:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return list;
  }

  void _showSettingsModal() {
    final downloadNotifier = ref.read(downloadProvider.notifier);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final state = ref.watch(downloadProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    Text('Download Settings', style: AppTextStyles.headline2),
                    const SizedBox(height: 20),
                    // Wi-Fi Only Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Download over Wi-Fi only',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text('Save mobile cellular data',
                          style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                      value: state.wifiOnly,
                      activeThumbColor: AppColors.accent,
                      onChanged: (val) {
                        downloadNotifier.setWifiOnly(val);
                        setModalState(() {});
                      },
                    ),
                    const Divider(height: 24),
                    // Download Quality
                    Text('Download Audio Quality',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _qualityChip('96kbps', 'Standard (96 kbps)', state.preferredQuality, (q) {
                          downloadNotifier.setPreferredQuality(q);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 8),
                        _qualityChip('160kbps', 'High (160 kbps)', state.preferredQuality, (q) {
                          downloadNotifier.setPreferredQuality(q);
                          setModalState(() {});
                        }),
                        const SizedBox(width: 8),
                        _qualityChip('320kbps', 'Very High (320 kbps)', state.preferredQuality, (q) {
                          downloadNotifier.setPreferredQuality(q);
                          setModalState(() {});
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _qualityChip(String value, String label, String current, ValueChanged<String> onSelected) {
    final isSelected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.divider.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value == '96kbps' ? 'Data Saver' : (value == '160kbps' ? 'Recommended' : 'Studio HD'),
                style: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.textHint,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSelected(List<DownloadedSong> downloads) {
    final selectedSongs = downloads.where((d) => _selectedSongIds.contains(d.songId)).toList();
    final totalSize = selectedSongs.fold(0, (sum, s) => sum + s.fileSizeBytes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text('Remove ${selectedSongs.length} downloads?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'This will free ${_formatBytes(totalSize)} of local storage. The songs will remain in your online library.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final song in selectedSongs) {
                ref.read(downloadProvider.notifier).removeDownload(song.songId);
              }
              setState(() {
                _isSelectionMode = false;
                _selectedSongIds.clear();
              });
            },
            child: Text('Remove', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
    final downloadState = ref.read(downloadProvider);
    if (downloadState.downloads.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text('Remove all downloads?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'This will remove all ${downloadState.downloads.length} offline songs (${_formatBytes(downloadState.totalStorageBytes)}).',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(downloadProvider.notifier).removeAllDownloads();
            },
            child: Text('Clear All', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadProvider);
    final downloads = downloadState.downloads;
    final queue = downloadState.queue;
    final activeQueue = queue.where((q) => q.status != DownloadStatus.completed).toList();
    final sortedDownloads = _getSortedAndFilteredDownloads(downloads);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // ─── App Bar ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Downloads', style: AppTextStyles.headline1),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (!downloadState.isOnline) ...[
                                Icon(Icons.offline_bolt_rounded,
                                    color: AppColors.tertiary, size: 14),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                downloadState.isOnline
                                    ? 'Available Offline'
                                    : 'Offline Mode Active',
                                style: TextStyle(
                                  color: downloadState.isOnline
                                      ? AppColors.accent
                                      : AppColors.tertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.tune_rounded, color: AppColors.textPrimary),
                        tooltip: 'Download Settings',
                        onPressed: _showSettingsModal,
                      ),
                      if (downloads.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.delete_sweep_rounded, color: AppColors.textHint),
                          tooltip: 'Storage Cleanup',
                          onPressed: _confirmDeleteAll,
                        ),
                    ],
                  ),
                ),
              ),

              // ─── Storage Overview Card ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surfaceContainerHigh,
                          AppColors.surfaceContainerLow,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.offline_pin_rounded, color: AppColors.accent, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Music Storage',
                                        style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                                    Text(
                                      _formatBytes(downloadState.totalStorageBytes),
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${downloads.length} Songs',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Storage Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (downloadState.totalStorageBytes / (1024 * 1024 * 1024 * 5)).clamp(0.02, 1.0),
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Active Queue Summary Banner (if active) ───
              if (activeQueue.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(AppColors.accent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Downloading ${activeQueue.length} song${activeQueue.length > 1 ? 's' : ''}...',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _tabController.animateTo(1);
                            },
                            child: Text('View Queue', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ─── Tabs Bar ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: 'Downloaded (${downloads.length})'),
                        Tab(text: 'Download Queue (${activeQueue.length})'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // ─── TAB 1: Downloaded Songs ───
              downloads.isEmpty
                  ? EmptyStateView(
                      icon: Icons.cloud_download_outlined,
                      title: 'No downloads yet',
                      subtitle: 'Download songs from Home or Search to enjoy smooth offline listening anytime.',
                      actionLabel: 'Explore Music',
                      onAction: () => context.go('/'),
                    )
                  : Column(
                      children: [
                        // Controls Bar: Search, Play All, Sort, Select
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          child: Row(
                            children: [
                              // Play All Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (sortedDownloads.isNotEmpty) {
                                    final tracks = sortedDownloads.map((d) => d.toTrack()).toList();
                                    ref.read(playerProvider.notifier).play(tracks.first, queue: tracks);
                                  }
                                },
                                icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                                label: const Text('Play All', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Shuffle Button
                              IconButton(
                                icon: Icon(Icons.shuffle_rounded, color: AppColors.textPrimary),
                                tooltip: 'Shuffle All',
                                onPressed: () {
                                  if (sortedDownloads.isNotEmpty) {
                                    final tracks = sortedDownloads.map((d) => d.toTrack()).toList()..shuffle();
                                    ref.read(playerProvider.notifier).play(tracks.first, queue: tracks);
                                  }
                                },
                              ),
                              const Spacer(),
                              // Selection Mode Toggle
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSelectionMode = !_isSelectionMode;
                                    _selectedSongIds.clear();
                                  });
                                },
                                child: Text(
                                  _isSelectionMode ? 'Done' : 'Select',
                                  style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Sort Menu
                              PopupMenuButton<DownloadSortOption>(
                                icon: Icon(Icons.sort_rounded, color: AppColors.textPrimary),
                                color: AppColors.surfaceContainerLow,
                                initialValue: _sortOption,
                                onSelected: (opt) => setState(() => _sortOption = opt),
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: DownloadSortOption.recent,
                                    child: Text('Recently Downloaded', style: TextStyle(color: Colors.white)),
                                  ),
                                  const PopupMenuItem(
                                    value: DownloadSortOption.largest,
                                    child: Text('Largest Size', style: TextStyle(color: Colors.white)),
                                  ),
                                  const PopupMenuItem(
                                    value: DownloadSortOption.alphabetical,
                                    child: Text('Title (A to Z)', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Selection Action Bar (when selecting)
                        if (_isSelectionMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            color: AppColors.surfaceContainerHigh,
                            child: Row(
                              children: [
                                Text(
                                  '${_selectedSongIds.length} selected',
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_selectedSongIds.length == sortedDownloads.length) {
                                        _selectedSongIds.clear();
                                      } else {
                                        _selectedSongIds.addAll(sortedDownloads.map((d) => d.songId));
                                      }
                                    });
                                  },
                                  child: Text(
                                    _selectedSongIds.length == sortedDownloads.length ? 'Deselect All' : 'Select All',
                                    style: TextStyle(color: AppColors.accent),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.secondary),
                                  onPressed: _selectedSongIds.isEmpty ? null : () => _confirmDeleteSelected(sortedDownloads),
                                ),
                              ],
                            ),
                          ),

                        // Song List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 120),
                            itemCount: sortedDownloads.length,
                            itemBuilder: (context, index) {
                              final download = sortedDownloads[index];
                              final track = download.toTrack();
                              final isSelected = _selectedSongIds.contains(download.songId);

                              return TrackTile(
                                track: track,
                                queue: sortedDownloads.map((d) => d.toTrack()).toList(),
                                isSelectable: _isSelectionMode,
                                isSelected: isSelected,
                                onSelectChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedSongIds.add(download.songId);
                                    } else {
                                      _selectedSongIds.remove(download.songId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),

              // ─── TAB 2: Download Queue ───
              activeQueue.isEmpty
                  ? EmptyStateView(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Queue is clear',
                      subtitle: 'No pending downloads. All songs are ready for offline playback.',
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  '${activeQueue.length} in queue',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Pause All
                              IconButton(
                                icon: const Icon(Icons.pause_circle_outline_rounded, size: 22),
                                color: AppColors.textSecondary,
                                tooltip: 'Pause All',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => ref.read(downloadProvider.notifier).pauseAll(),
                              ),
                              // Resume All
                              IconButton(
                                icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                                color: AppColors.accent,
                                tooltip: 'Resume All',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => ref.read(downloadProvider.notifier).resumeAll(),
                              ),
                              // Cancel All
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, size: 22),
                                color: AppColors.secondary,
                                tooltip: 'Cancel All',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => ref.read(downloadProvider.notifier).cancelAll(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 120),
                            itemCount: activeQueue.length,
                            itemBuilder: (context, index) {
                              final item = activeQueue[index];
                              final isDownloading = item.status == DownloadStatus.downloading;
                              final isPaused = item.status == DownloadStatus.paused;
                              final isFailed = item.status == DownloadStatus.failed;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDownloading
                                          ? AppColors.accent.withValues(alpha: 0.3)
                                          : AppColors.divider.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: CachedNetworkImage(
                                              imageUrl: item.track.imageUrl,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => Image.asset(
                                                'assets/images/app_icon.png',
                                                width: 44,
                                                height: 44,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.track.title,
                                                  style: AppTextStyles.trackTitle,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  isDownloading
                                                      ? '${(item.progress * 100).toInt()}% • ${_formatBytes(item.bytesDownloaded)} / ${_formatBytes(item.totalBytes)}'
                                                      : (isPaused ? 'Paused' : (isFailed ? 'Failed — Tap to retry' : 'Waiting in queue...')),
                                                  style: TextStyle(
                                                    color: isDownloading
                                                        ? AppColors.accent
                                                        : (isFailed ? AppColors.secondary : AppColors.textHint),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Control buttons
                                          if (isDownloading)
                                            IconButton(
                                              icon: Icon(Icons.pause_circle_outline_rounded, color: AppColors.textHint),
                                              onPressed: () => ref.read(downloadProvider.notifier).pauseDownload(item.id),
                                            )
                                          else if (isPaused)
                                            IconButton(
                                              icon: Icon(Icons.play_circle_outline_rounded, color: AppColors.accent),
                                              onPressed: () => ref.read(downloadProvider.notifier).resumeDownload(item.id),
                                            )
                                          else if (isFailed)
                                            IconButton(
                                              icon: Icon(Icons.refresh_rounded, color: AppColors.secondary),
                                              onPressed: () => ref.read(downloadProvider.notifier).retryDownload(item.id),
                                            ),
                                          IconButton(
                                            icon: Icon(Icons.close_rounded, color: AppColors.textHint, size: 20),
                                            onPressed: () => ref.read(downloadProvider.notifier).cancelDownload(item.id),
                                          ),
                                        ],
                                      ),
                                      if (isDownloading) ...[
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: item.progress > 0 ? item.progress : null,
                                            minHeight: 4,
                                            backgroundColor: AppColors.surfaceContainerHighest,
                                            valueColor: AlwaysStoppedAnimation(AppColors.accent),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
