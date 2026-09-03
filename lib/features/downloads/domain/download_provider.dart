import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/download_model.dart';
import '../../../shared/models/playlist_model.dart';
import '../../../shared/models/track_model.dart';
import '../../../shared/services/hive_service.dart';
import '../data/download_repository.dart';

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepository();
});

class DownloadState {
  final List<DownloadedSong> downloads;
  final List<DownloadQueueItem> queue;
  final bool wifiOnly;
  final String preferredQuality;
  final bool isOnline;

  const DownloadState({
    this.downloads = const [],
    this.queue = const [],
    this.wifiOnly = false,
    this.preferredQuality = '96kbps',
    this.isOnline = true,
  });

  int get totalStorageBytes =>
      downloads.fold(0, (sum, song) => sum + song.fileSizeBytes);

  DownloadState copyWith({
    List<DownloadedSong>? downloads,
    List<DownloadQueueItem>? queue,
    bool? wifiOnly,
    String? preferredQuality,
    bool? isOnline,
  }) {
    return DownloadState(
      downloads: downloads ?? this.downloads,
      queue: queue ?? this.queue,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      preferredQuality: preferredQuality ?? this.preferredQuality,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  final DownloadRepository _repo;
  final Set<String> _activeDownloadingIds = {};
  static const int _maxConcurrent = 2;
  StreamSubscription? _connectivitySub;

  DownloadNotifier(this._repo) : super(const DownloadState()) {
    _loadState();
    _listenConnectivity();
    _processNextInQueue();
  }

  void _loadState() {
    final wifiOnly = HiveService.settings.get('download_wifi_only', defaultValue: false) as bool;
    final quality = HiveService.settings.get('download_quality', defaultValue: '96kbps') as String;

    state = state.copyWith(
      downloads: _repo.getDownloads(),
      queue: _repo.getQueue(),
      wifiOnly: wifiOnly,
      preferredQuality: quality,
    );
  }

  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      final isWifi = results.any((r) => r == ConnectivityResult.wifi);

      state = state.copyWith(isOnline: isOnline);

      if (!isOnline) {
        pauseAll();
      } else if (isWifi || !state.wifiOnly) {
        resumeAll();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  bool isDownloaded(String songId) {
    return state.downloads.any((d) => d.songId == songId);
  }

  DownloadStatus getStatus(String songId) {
    if (isDownloaded(songId)) return DownloadStatus.completed;
    final inQueue = state.queue.where((q) => q.track.id == songId);
    if (inQueue.isNotEmpty) return inQueue.first.status;
    return DownloadStatus.notDownloaded;
  }

  double getProgress(String songId) {
    final inQueue = state.queue.where((q) => q.track.id == songId);
    if (inQueue.isNotEmpty) return inQueue.first.progress;
    if (isDownloaded(songId)) return 1.0;
    return 0.0;
  }

  DownloadedSong? getDownloadedSong(String songId) {
    return _repo.getDownloadedSong(songId);
  }

  Future<void> downloadTrack(TrackModel track) async {
    if (isDownloaded(track.id)) return;
    await _repo.enqueueTrack(track, quality: state.preferredQuality);
    _syncQueue();
    _processNextInQueue();
  }

  Future<void> downloadPlaylist(PlaylistModel playlist) async {
    await _repo.enqueuePlaylist(playlist, quality: state.preferredQuality);
    _syncQueue();
    _processNextInQueue();
  }

  Future<void> downloadTracks(List<TrackModel> tracks) async {
    await _repo.enqueueTracks(tracks, quality: state.preferredQuality);
    _syncQueue();
    _processNextInQueue();
  }

  void pauseDownload(String queueId) {
    _repo.pauseDownload(queueId);
    _activeDownloadingIds.remove(queueId);
    _updateQueueItemStatus(queueId, DownloadStatus.paused);
  }

  void resumeDownload(String queueId) {
    _updateQueueItemStatus(queueId, DownloadStatus.queued);
    _processNextInQueue();
  }

  void cancelDownload(String queueId) {
    _repo.cancelDownload(queueId);
    _activeDownloadingIds.remove(queueId);
    _syncQueue();
    _processNextInQueue();
  }

  void retryDownload(String queueId) {
    _updateQueueItemStatus(queueId, DownloadStatus.queued);
    _processNextInQueue();
  }

  void pauseAll() {
    for (final id in _activeDownloadingIds.toList()) {
      _repo.pauseDownload(id);
    }
    _activeDownloadingIds.clear();
    final updatedQueue = state.queue.map((item) {
      if (item.status == DownloadStatus.downloading || item.status == DownloadStatus.queued) {
        return item.copyWith(status: DownloadStatus.paused);
      }
      return item;
    }).toList();
    for (final item in updatedQueue) {
      HiveService.queue.put(item.id, item);
    }
    state = state.copyWith(queue: updatedQueue);
  }

  void resumeAll() {
    final updatedQueue = state.queue.map((item) {
      if (item.status == DownloadStatus.paused) {
        return item.copyWith(status: DownloadStatus.queued);
      }
      return item;
    }).toList();
    for (final item in updatedQueue) {
      HiveService.queue.put(item.id, item);
    }
    state = state.copyWith(queue: updatedQueue);
    _processNextInQueue();
  }

  void cancelAll() {
    for (final item in state.queue) {
      _repo.cancelDownload(item.id);
    }
    _activeDownloadingIds.clear();
    _syncQueue();
  }

  Future<void> removeDownload(String songId) async {
    await _repo.deleteDownload(songId);
    state = state.copyWith(downloads: _repo.getDownloads());
  }

  Future<void> removeAllDownloads() async {
    await _repo.deleteAllDownloads();
    state = state.copyWith(downloads: _repo.getDownloads());
  }

  void setWifiOnly(bool value) {
    HiveService.settings.put('download_wifi_only', value);
    state = state.copyWith(wifiOnly: value);
  }

  void setPreferredQuality(String quality) {
    HiveService.settings.put('download_quality', quality);
    state = state.copyWith(preferredQuality: quality);
  }

  void _syncQueue() {
    state = state.copyWith(
      queue: _repo.getQueue(),
      downloads: _repo.getDownloads(),
    );
  }

  void _updateQueueItemStatus(String queueId, DownloadStatus status, {String? error}) {
    final idx = state.queue.indexWhere((q) => q.id == queueId);
    if (idx >= 0) {
      final updated = state.queue[idx].copyWith(status: status, errorMessage: error);
      HiveService.queue.put(queueId, updated);
      final list = List<DownloadQueueItem>.from(state.queue);
      list[idx] = updated;
      state = state.copyWith(queue: list);
    }
  }

  void _processNextInQueue() {
    if (_activeDownloadingIds.length >= _maxConcurrent) return;

    final pending = state.queue
        .where((q) => q.status == DownloadStatus.queued && !_activeDownloadingIds.contains(q.id))
        .toList();

    if (pending.isEmpty) return;

    final nextItem = pending.first;
    _activeDownloadingIds.add(nextItem.id);
    _updateQueueItemStatus(nextItem.id, DownloadStatus.downloading);

    _repo.processDownload(
      nextItem,
      onProgress: (progress, bytes, total) {
        final idx = state.queue.indexWhere((q) => q.id == nextItem.id);
        if (idx >= 0) {
          final updated = state.queue[idx].copyWith(
            progress: progress,
            bytesDownloaded: bytes,
            totalBytes: total,
            status: DownloadStatus.downloading,
          );
          final list = List<DownloadQueueItem>.from(state.queue);
          list[idx] = updated;
          state = state.copyWith(queue: list);
        }
      },
      onComplete: (downloadedSong) {
        _activeDownloadingIds.remove(nextItem.id);
        _syncQueue();
        _processNextInQueue();
      },
      onError: (error) {
        _activeDownloadingIds.remove(nextItem.id);
        _updateQueueItemStatus(nextItem.id, DownloadStatus.failed, error: error);
        _processNextInQueue();
      },
    );
  }
}

final downloadProvider =
    StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  return DownloadNotifier(ref.read(downloadRepositoryProvider));
});
