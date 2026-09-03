import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../shared/models/download_model.dart';
import '../../../shared/models/track_model.dart';
import '../../../shared/models/playlist_model.dart';
import '../../../shared/services/hive_service.dart';
import '../../player/data/stream_resolver.dart';

class DownloadRepository {
  final StreamResolver _resolver;
  final Map<String, http.Client> _activeClients = {};
  final Map<String, bool> _cancelFlags = {};
  final Map<String, bool> _pauseFlags = {};

  DownloadRepository([StreamResolver? resolver])
      : _resolver = resolver ?? StreamResolver();

  List<DownloadedSong> getDownloads() {
    return HiveService.downloads.values.toList();
  }

  List<DownloadQueueItem> getQueue() {
    return HiveService.queue.values.toList();
  }

  bool isDownloaded(String songId) {
    return HiveService.downloads.values.any((d) => d.songId == songId);
  }

  DownloadedSong? getDownloadedSong(String songId) {
    try {
      return HiveService.downloads.values.firstWhere((d) => d.songId == songId);
    } catch (_) {
      return null;
    }
  }

  Future<String> _getStorageDirectory() async {
    if (kIsWeb) return 'web_cache';
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/raaga_downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  String _sanitizeFileName(String input) {
    return input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<void> enqueueTrack(TrackModel track, {String quality = '96kbps'}) async {
    if (isDownloaded(track.id)) return;

    final existingIndex = HiveService.queue.values.toList().indexWhere((q) => q.track.id == track.id);
    if (existingIndex >= 0) return;

    final queueItem = DownloadQueueItem(
      id: 'download_${track.id}',
      track: track,
      status: DownloadStatus.queued,
      quality: quality,
      createdAt: DateTime.now(),
    );

    await HiveService.queue.put(queueItem.id, queueItem);
  }

  Future<void> enqueuePlaylist(PlaylistModel playlist, {String quality = '96kbps'}) async {
    for (final track in playlist.tracks) {
      await enqueueTrack(track, quality: quality);
    }
  }

  Future<void> enqueueTracks(List<TrackModel> tracks, {String quality = '96kbps'}) async {
    for (final track in tracks) {
      await enqueueTrack(track, quality: quality);
    }
  }

  Future<void> processDownload(
    DownloadQueueItem item, {
    required Function(double progress, int bytesDownloaded, int totalBytes) onProgress,
    required Function(DownloadedSong downloadedSong) onComplete,
    required Function(String error) onError,
  }) async {
    final track = item.track;
    _cancelFlags[item.id] = false;
    _pauseFlags[item.id] = false;

    try {
      // 1. Resolve stream URL
      String streamUrl = track.streamUrl ?? '';
      if (streamUrl.isEmpty || track.source == 'youtube') {
        streamUrl = await _resolver.resolve(track);
      }

      if (streamUrl.isEmpty) {
        throw Exception('Stream URL could not be resolved');
      }

      // Map stream URL to chosen bitrate quality for JioSaavn
      if (item.quality == '96kbps') {
        streamUrl = streamUrl
            .replaceAll('_320.mp4', '_96.mp4')
            .replaceAll('_160.mp4', '_96.mp4');
      } else if (item.quality == '160kbps') {
        streamUrl = streamUrl
            .replaceAll('_320.mp4', '_160.mp4')
            .replaceAll('_96.mp4', '_160.mp4');
      } else if (item.quality == '320kbps') {
        streamUrl = streamUrl
            .replaceAll('_96.mp4', '_320.mp4')
            .replaceAll('_160.mp4', '_320.mp4');
      }

      if (_cancelFlags[item.id] == true) return;

      // 2. Prepare file destination
      final storagePath = await _getStorageDirectory();
      final ext = streamUrl.contains('.mp4') ? 'm4a' : 'mp3';
      final safeTitle = _sanitizeFileName('${track.artist}_${track.title}_${track.id}');
      final filePath = '$storagePath/$safeTitle.$ext';
      final file = File(filePath);

      // 3. Initiate HTTP download with streaming
      final client = http.Client();
      _activeClients[item.id] = client;

      final request = http.Request('GET', Uri.parse(streamUrl));
      final response = await client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        if (_cancelFlags[item.id] == true) {
          await sink.close();
          if (await file.exists()) await file.delete();
          client.close();
          _activeClients.remove(item.id);
          return;
        }

        if (_pauseFlags[item.id] == true) {
          await sink.close();
          client.close();
          _activeClients.remove(item.id);
          return;
        }

        sink.add(chunk);
        bytesReceived += chunk.length;

        double progress = 0.0;
        if (contentLength > 0) {
          progress = (bytesReceived / contentLength).clamp(0.0, 1.0);
        } else {
          // Approximate progress
          progress = (bytesReceived / (5 * 1024 * 1024)).clamp(0.0, 0.95);
        }

        onProgress(progress, bytesReceived, contentLength);
      }

      await sink.flush();
      await sink.close();
      client.close();
      _activeClients.remove(item.id);

      final totalSize = bytesReceived > 0 ? bytesReceived : (await file.length());

      final downloadedSong = DownloadedSong(
        id: 'download_${track.id}',
        songId: track.id,
        title: track.title,
        artist: track.artist,
        imageUrl: track.imageUrl,
        localPath: filePath,
        fileSizeBytes: totalSize,
        durationSeconds: track.durationSeconds,
        album: track.album,
        source: track.source,
        downloadedAt: DateTime.now(),
        quality: item.quality,
      );

      // Save to Hive
      await HiveService.downloads.put(downloadedSong.id, downloadedSong);
      await HiveService.queue.delete(item.id);

      onComplete(downloadedSong);
    } catch (e) {
      _activeClients[item.id]?.close();
      _activeClients.remove(item.id);
      onError(e.toString());
    }
  }

  void pauseDownload(String queueId) {
    _pauseFlags[queueId] = true;
    _activeClients[queueId]?.close();
    _activeClients.remove(queueId);
  }

  void cancelDownload(String queueId) {
    _cancelFlags[queueId] = true;
    _activeClients[queueId]?.close();
    _activeClients.remove(queueId);
    HiveService.queue.delete(queueId);
  }

  Future<void> deleteDownload(String songId) async {
    final downloaded = getDownloadedSong(songId);
    if (downloaded != null) {
      try {
        final file = File(downloaded.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting local file: $e');
      }
      await HiveService.downloads.delete(downloaded.id);
    }
  }

  Future<void> deleteAllDownloads() async {
    final downloads = getDownloads();
    for (final song in downloads) {
      try {
        final file = File(song.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    await HiveService.downloads.clear();
  }

  int getTotalStorageUsedBytes() {
    return getDownloads().fold(0, (sum, song) => sum + song.fileSizeBytes);
  }
}
