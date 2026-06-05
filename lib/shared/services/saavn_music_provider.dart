import 'dart:convert';
import 'dart:math';

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

  // ── Large rotating query pools per language ──────────────────────────────
  // Each pool has multiple variants so different ones are picked across the day.
  static const Map<String, List<String>> _trendingQueryPools = {
    'hindi': [
      'top bollywood songs 2025',
      'latest hindi hits this week',
      'trending bollywood 2025',
      'new hindi releases june 2025',
      'popular bollywood chartbusters',
      'best new hindi songs today',
      'bollywood superhits 2025',
      'hot hindi party songs',
      'latest romantic hindi songs',
      'bollywood blockbuster songs 2025',
    ],
    'tamil': [
      'top kollywood songs 2025',
      'trending tamil hits this week',
      'new tamil releases 2025',
      'popular tamil songs today',
      'latest tamil chartbusters',
      'kollywood blockbuster songs',
      'trending tamil melody songs',
      'new tamil movie songs 2025',
    ],
    'telugu': [
      'top tollywood songs 2025',
      'trending telugu hits this week',
      'new telugu releases 2025',
      'popular telugu songs today',
      'latest tollywood chartbusters',
      'telugu blockbuster songs 2025',
      'trending telugu melody',
      'new telugu movie songs',
    ],
    'kannada': [
      'top sandalwood songs 2025',
      'trending kannada hits this week',
      'new kannada releases 2025',
      'popular kannada songs today',
      'latest kannada chartbusters',
      'kannada blockbuster songs 2025',
    ],
    'malayalam': [
      'top mollywood songs 2025',
      'trending malayalam hits',
      'new malayalam releases 2025',
      'popular malayalam songs today',
      'latest malayalam chartbusters',
      'mollywood hits 2025',
    ],
    'punjabi': [
      'top punjabi songs 2025',
      'trending punjabi hits this week',
      'new punjabi releases 2025',
      'popular punjabi songs today',
      'latest punjabi pop 2025',
      'punjabi chartbusters this month',
      'desi punjabi beats 2025',
    ],
    'bengali': [
      'top bengali songs 2025',
      'trending bengali hits',
      'new bengali releases 2025',
      'popular bengali songs today',
      'latest bengali chartbusters',
    ],
    'marathi': [
      'top marathi songs 2025',
      'trending marathi hits this week',
      'new marathi releases 2025',
      'popular marathi songs today',
      'latest marathi chartbusters',
    ],
    'gujarati': [
      'top gujarati songs 2025',
      'trending gujarati garba hits',
      'new gujarati releases 2025',
      'popular gujarati songs today',
      'latest gujarati chartbusters',
    ],
    'bhojpuri': [
      'top bhojpuri songs 2025',
      'trending bhojpuri hits this week',
      'new bhojpuri releases 2025',
      'popular bhojpuri songs today',
    ],
    'haryanvi': [
      'top haryanvi songs 2025',
      'trending haryanvi hits',
      'new haryanvi releases 2025',
      'popular haryanvi songs today',
    ],
    'rajasthani': [
      'top rajasthani folk songs 2025',
      'trending rajasthani hits',
      'new rajasthani releases 2025',
      'popular rajasthani songs today',
    ],
    'odia': [
      'top odia songs 2025',
      'trending odia hits this week',
      'new odia releases 2025',
      'popular odia songs today',
    ],
    'english': [
      'top english hits 2025',
      'trending pop songs this week',
      'new international releases 2025',
      'billboard hot 100 2025',
      'best english songs today',
      'popular western songs 2025',
      'top english chartbusters',
    ],
    'urdu': [
      'top urdu ghazals 2025',
      'trending urdu songs',
      'new urdu releases 2025',
      'popular urdu poetry songs',
      'best urdu qawwali 2025',
    ],
  };

  @override
  Future<List<TrackModel>> search(String query, {int limit = 20, int page = 1}) async {
    final rawUrl = '${ApiConfig.saavnBaseUrl}'
        '?__call=search.getResults'
        '&_format=json&_marker=0&api_version=4&ctx=web6dot0'
        '&n=$limit'
        '&p=$page'
        '&q=${Uri.encodeComponent(query)}';

    // On web, wrap through CORS proxy so the browser can fetch it
    final url = WebProxy.wrap(rawUrl);
    return _fetchTracks(url);
  }

  @override
  Future<List<TrackModel>> getTrending(String language, {int limit = 20}) async {
    final now = DateTime.now();

    // Rotate query every 30 minutes throughout the day (48 unique slots/day).
    // This ensures users see different songs every session.
    final timeSlot = now.millisecondsSinceEpoch ~/ (30 * 60 * 1000);

    final pool = _trendingQueryPools[language] ??
        [
          'trending $language songs 2025',
          'top $language hits today',
          'new $language releases 2025',
          'popular $language songs',
        ];

    final query = pool[timeSlot % pool.length];

    debugPrint('SaavnMusicProvider: getTrending($language) → "$query"');
    return search(query, limit: limit, page: 1);
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

      final tracks = results.map<TrackModel>((song) => _parseSong(song)).toList();

      // Shuffle tracks so the order feels fresh even for the same query results
      tracks.shuffle(Random(timeSlot));

      return tracks;
    } catch (e) {
      debugPrint('SaavnMusicProvider error: $e');
      return [];
    }
  }

  // Current 30-min time slot (used for shuffle seed)
  int get timeSlot => DateTime.now().millisecondsSinceEpoch ~/ (30 * 60 * 1000);

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
