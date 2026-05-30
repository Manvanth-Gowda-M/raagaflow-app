import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/desede_engine.dart';
import 'package:pointycastle/block/modes/ecb.dart';

import '../../core/constants/api_config.dart';
import '../../core/utils/web_proxy.dart';
import '../models/track_model.dart';
import 'music_provider.dart';

/// Concrete [MusicProvider] implementation for JioSaavn.
/// Hits JioSaavn's internal API directly — no third-party wrapper needed.
class SaavnMusicProvider implements MusicProvider {
  @override
  String get sourceName => 'saavn';

  static const _userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';

  // DES-ECB key used by JioSaavn to encrypt media URLs (publicly known).
  static final _desKeyBytes = Uint8List.fromList(utf8.encode('38346591'));

  @override
  Future<List<TrackModel>> search(String query, {int limit = 20}) async {
    final rawUrl = '${ApiConfig.saavnBaseUrl}'
        '?__call=search.getResults'
        '&_format=json&_marker=0&api_version=4&ctx=web6dot0'
        '&n=$limit'
        '&q=${Uri.encodeComponent(query)}';

    // On web, wrap through CORS proxy so the browser can fetch it
    final url = WebProxy.wrap(rawUrl);
    return _fetchTracks(url);
  }

  @override
  Future<List<TrackModel>> getTrending(String language, {int limit = 20}) async {
    final queryMap = {
      'hindi': 'latest bollywood hits',
      'tamil': 'trending tamil songs',
      'telugu': 'top telugu songs',
      'kannada': 'new kannada songs',
      'malayalam': 'trending malayalam songs',
      'punjabi': 'top punjabi songs',
      'bengali': 'new bengali songs',
      'marathi': 'trending marathi songs',
      'gujarati': 'new gujarati songs',
      'bhojpuri': 'top bhojpuri songs',
      'haryanvi': 'new haryanvi songs',
      'rajasthani': 'top rajasthani songs',
      'odia': 'new odia songs',
      'english': 'top english songs',
      'urdu': 'best urdu ghazals',
    };
    return search(queryMap[language] ?? 'trending $language songs', limit: limit);
  }

  Future<List<TrackModel>> _fetchTracks(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('SaavnMusicProvider: HTTP ${response.statusCode}');
        return [];
      }

      final body = utf8.decode(response.bodyBytes);
      if (!body.startsWith('{')) {
        debugPrint('SaavnMusicProvider: Non-JSON response');
        return [];
      }

      final data = jsonDecode(body);
      final results = data['results'] as List? ?? [];

      return results.map<TrackModel>((song) => _parseSong(song)).toList();
    } catch (e) {
      debugPrint('SaavnMusicProvider error: $e');
      return [];
    }
  }

  TrackModel _parseSong(Map<String, dynamic> song) {
    final moreInfo = song['more_info'] as Map<String, dynamic>? ?? {};

    // Decrypt the media URL
    final encryptedUrl = moreInfo['encrypted_media_url'] as String? ?? '';
    String streamUrl = '';
    if (encryptedUrl.isNotEmpty) {
      streamUrl = _decryptUrl(encryptedUrl);
      // Replace quality to get 320kbps if available
      if (moreInfo['320kbps'] == 'true' || moreInfo['320kbps'] == true) {
        streamUrl = streamUrl.replaceAll('_96.mp4', '_320.mp4');
      } else {
        streamUrl = streamUrl.replaceAll('_96.mp4', '_160.mp4');
      }
    }

    debugPrint('SaavnMusicProvider: Decrypted URL = $streamUrl');

    // Parse image — use the highest resolution version
    String imageUrl = (song['image'] as String? ?? '')
        .replaceAll('150x150', '500x500')
        .replaceAll('50x50', '500x500');

    // Parse artist from subtitle (format: "artist - album")
    final subtitle = song['subtitle'] as String? ?? '';
    final artist = subtitle.contains(' - ')
        ? subtitle.split(' - ').first.trim()
        : subtitle;

    return TrackModel(
      id: 'saavn_${song['id']}',
      title: _cleanHtml(song['title'] as String? ?? 'Unknown'),
      artist: _cleanHtml(artist.isNotEmpty ? artist : 'Unknown Artist'),
      imageUrl: imageUrl,
      source: sourceName,
      streamUrl: streamUrl,
      durationSeconds: int.tryParse(moreInfo['duration']?.toString() ?? '0'),
      album: _cleanHtml(moreInfo['album'] as String? ?? ''),
      language: song['language'] as String?,
    );
  }

  /// Decrypts a JioSaavn encrypted media URL using DES-ECB.
  /// Uses Triple-DES (DESedeEngine) with key repeated 3x (equivalent to single DES).
  String _decryptUrl(String encryptedUrl) {
    try {
      final encryptedBytes = base64.decode(encryptedUrl);

      // DES with key K === DESede with key K+K+K
      final key24 = Uint8List.fromList([..._desKeyBytes, ..._desKeyBytes, ..._desKeyBytes]);
      final cipher = ECBBlockCipher(DESedeEngine());
      cipher.init(false, KeyParameter(key24)); // false = decrypt

      final decryptedBytes = Uint8List(encryptedBytes.length);
      for (var offset = 0; offset < encryptedBytes.length; offset += cipher.blockSize) {
        cipher.processBlock(encryptedBytes, offset, decryptedBytes, offset);
      }

      // Remove PKCS7 padding
      final padLength = decryptedBytes.last;
      if (padLength > 0 && padLength <= 8) {
        final unpadded = decryptedBytes.sublist(0, decryptedBytes.length - padLength);
        return utf8.decode(unpadded);
      }
      return utf8.decode(decryptedBytes);
    } catch (e) {
      debugPrint('DES decryption failed: $e');
      return '';
    }
  }

  /// Remove HTML entities and tags from JioSaavn strings.
  String _cleanHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
