import 'package:flutter_test/flutter_test.dart';
import 'package:raagaflow/shared/models/download_model.dart';
import 'package:raagaflow/shared/models/track_model.dart';

void main() {
  group('Download Models and Offline Storage Tests', () {
    test('DownloadedSong model serialization & toTrack', () {
      final downloadedSong = DownloadedSong(
        id: 'download_123',
        songId: '123',
        title: 'Kannada Night Lofi',
        artist: 'RaagaFlow Artist',
        imageUrl: 'https://example.com/art.jpg',
        localPath: '/storage/emulated/0/raaga_downloads/kannada_lofi.mp3',
        fileSizeBytes: 4500000,
        durationSeconds: 180,
        album: 'Lofi Bengaluru',
        source: 'saavn',
        downloadedAt: DateTime(2026, 6, 1),
        quality: '160kbps',
      );

      expect(downloadedSong.id, 'download_123');
      expect(downloadedSong.songId, '123');
      expect(downloadedSong.fileSizeBytes, 4500000);

      final track = downloadedSong.toTrack();
      expect(track.id, '123');
      expect(track.title, 'Kannada Night Lofi');
      expect(track.source, 'offline');
      expect(track.streamUrl, '/storage/emulated/0/raaga_downloads/kannada_lofi.mp3');
    });

    test('DownloadQueueItem progress and state update', () {
      const track = TrackModel(
        id: '456',
        title: 'Hindi Late Night',
        artist: 'Arijit Singh',
        imageUrl: 'https://example.com/art2.jpg',
        source: 'saavn',
      );

      final queueItem = DownloadQueueItem(
        id: 'download_456',
        track: track,
        status: DownloadStatus.queued,
        createdAt: DateTime.now(),
      );

      expect(queueItem.status, DownloadStatus.queued);
      expect(queueItem.progress, 0.0);

      final downloadingItem = queueItem.copyWith(
        status: DownloadStatus.downloading,
        progress: 0.55,
        bytesDownloaded: 2200000,
        totalBytes: 4000000,
      );

      expect(downloadingItem.status, DownloadStatus.downloading);
      expect(downloadingItem.progress, 0.55);
      expect(downloadingItem.bytesDownloaded, 2200000);
      expect(downloadingItem.totalBytes, 4000000);

      final completedItem = downloadingItem.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
      );

      expect(completedItem.status, DownloadStatus.completed);
      expect(completedItem.progress, 1.0);
    });
  });
}
