import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/web_proxy.dart';
import '../../../shared/models/track_model.dart';

class StreamResolver {
  final _yt = YoutubeExplode();

  /// Public Piped API instances — tried in order if primary resolution fails.
  static const _pipedInstances = [
    'https://api.piped.yt',
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.in.projectsegfau.lt',
    'https://pipedapi.smnz.de',
    'https://piped-api.lunar.icu',
    'https://yt.artemislena.eu',
  ];

  Future<String> resolve(TrackModel track) async {
    switch (track.source) {
      case 'youtube':
        final videoId = track.youtubeId!;
        debugPrint('Resolving YouTube stream for: $videoId (web: $kIsWeb)');

        if (kIsWeb) {
          // On web: youtube_explode_dart is CORS-blocked.
          // Go straight to Piped which returns HLS/DASH streams with CORS headers.
          debugPrint('[Web] Skipping youtube_explode, trying Piped HLS...');
          final pipedUrl = await _resolveViaPipedWeb(videoId);
          if (pipedUrl != null) {
            debugPrint('[Web] Resolved via Piped: $pipedUrl');
            return pipedUrl;
          }
          throw const AppException(
              'Cannot play this track in the browser. Try the Android app for full playback.');
        }

        // Stage 1: Try youtube_explode_dart (native only)
        try {
          final manifest = await _yt.videos.streamsClient.getManifest(
            videoId,
            ytClients: [YoutubeApiClient.ios],
          );
          // Prefer M4A (AAC) as it has better hardware support on some Android devices
          final streamInfo = manifest.audioOnly
                  .where((s) => s.container == StreamContainer.mp4)
                  .toList()
                  .isEmpty
              ? manifest.audioOnly.withHighestBitrate()
              : manifest.audioOnly
                  .where((s) => s.container == StreamContainer.mp4)
                  .withHighestBitrate();

          debugPrint(
              'Resolved via youtube_explode_dart (${streamInfo.container.name}): ${streamInfo.url}');
          return streamInfo.url.toString();
        } catch (e) {
          debugPrint('youtube_explode_dart iOS client failed for $videoId: $e');
        }

        // Stage 2: Fallback to Piped API (native)
        debugPrint('Stage 2: Attempting Piped API fallback for $videoId');
        final pipedUrl = await _resolveViaPiped(videoId);
        if (pipedUrl != null) {
          debugPrint('Resolved via Piped: $pipedUrl');
          return pipedUrl;
        }

        debugPrint('All resolution stages failed for $videoId');
        throw const AppException(
            'Cannot play this track. YouTube is temporarily blocking requests. Please try again later.');

      case 'saavn':
        // JioSaavn streams are pre-resolved CDN URLs — no resolution needed
        if (track.streamUrl != null && track.streamUrl!.isNotEmpty) {
          debugPrint('Playing JioSaavn stream: ${track.streamUrl}');
          // On web, JioSaavn CDN serves audio with CORS headers — no proxy needed
          return track.streamUrl!;
        }
        throw const AppException('No stream URL available for this track');

      case 'jamendo':
      case 'pixabay':
        if (track.streamUrl != null) return track.streamUrl!;
        throw const AppException('No stream URL available');

      default:
        throw AppException('Unknown source: ${track.source}');
    }
  }

  /// Web-specific Piped resolver — proxies the API call (CORS) then returns
  /// the raw HLS/DASH URL. Piped's actual stream URLs have CORS headers and
  /// can be played directly by the browser's <audio> element via just_audio.
  Future<String?> _resolveViaPipedWeb(String videoId) async {
    for (final baseUrl in _pipedInstances) {
      try {
        debugPrint('[Web] Trying Piped instance: $baseUrl');
        final apiUrl = '$baseUrl/streams/$videoId';
        // Proxy only the API call — the resulting HLS URL is self-CORS-enabled
        final proxiedUrl = WebProxy.wrap(apiUrl);

        final response = await http.get(
          Uri.parse(proxiedUrl),
          headers: {
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is! Map) continue;

          // HLS is best for browser playback (Safari + Chrome via HLS.js)
          final hls = data['hls'] as String?;
          if (hls != null && hls.isNotEmpty) {
            debugPrint('[Web] Piped $baseUrl: Found HLS stream');
            return hls;
          }

          // DASH fallback
          final dash = data['dash'] as String?;
          if (dash != null && dash.isNotEmpty) {
            debugPrint('[Web] Piped $baseUrl: Found DASH stream');
            return dash;
          }

          // Direct audio stream fallback — pick highest bitrate
          final audioStreams = data['audioStreams'];
          if (audioStreams is List && audioStreams.isNotEmpty) {
            audioStreams.sort((a, b) =>
                ((b['bitrate'] as num?) ?? 0)
                    .compareTo((a['bitrate'] as num?) ?? 0));
            final url = audioStreams.first['url'] as String?;
            if (url != null && url.isNotEmpty) {
              debugPrint('[Web] Piped $baseUrl: Found direct audio stream');
              return url;
            }
          }
        } else {
          debugPrint('[Web] Piped $baseUrl returned status ${response.statusCode}');
          WebProxy.rotateProxy(); // Try next proxy if this one fails
        }
      } catch (e) {
        debugPrint('[Web] Piped instance $baseUrl failed: $e');
        continue;
      }
    }
    return null;
  }

  /// Tries each Piped instance and returns the best available stream URL (HLS > DASH > Direct).
  /// Native-only (no proxy needed).
  Future<String?> _resolveViaPiped(String videoId) async {
    for (final baseUrl in _pipedInstances) {
      try {
        debugPrint('Trying Piped instance: $baseUrl');
        final uri = Uri.parse('$baseUrl/streams/$videoId');
        final response = await http.get(
          uri,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is! Map) {
            debugPrint('Piped $baseUrl returned non-map JSON');
            continue;
          }

          // Choice 1: HLS (Adaptive, most stable)
          final hls = data['hls'] as String?;
          if (hls != null && hls.isNotEmpty) {
            debugPrint('Piped $baseUrl: Found HLS stream');
            return hls;
          }

          // Choice 2: DASH (Adaptive)
          final dash = data['dash'] as String?;
          if (dash != null && dash.isNotEmpty) {
            debugPrint('Piped $baseUrl: Found DASH stream');
            return dash;
          }

          // Choice 3: Direct Audio Streams
          final audioStreams = data['audioStreams'];
          if (audioStreams is List && audioStreams.isNotEmpty) {
            audioStreams.sort((a, b) =>
                ((b['bitrate'] as num?) ?? 0)
                    .compareTo((a['bitrate'] as num?) ?? 0));
            final url = audioStreams.first['url'] as String?;
            if (url != null && url.isNotEmpty) return url;
          } else {
            debugPrint('Piped $baseUrl returned no audio streams');
          }
        } else {
          debugPrint('Piped $baseUrl returned status ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Piped instance $baseUrl failed: $e');
        continue;
      }
    }
    return null;
  }

  void dispose() => _yt.close();
}
