import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/track_model.dart';
import '../../library/domain/library_provider.dart';
import '../../player/domain/player_provider.dart';
import './home_provider.dart';

class NotificationModel {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final bool isNew;
  final TrackModel? track;
  final String type; // 'trending' | 'release' | 'history' | 'system'
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isNew = true,
    this.track,
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? time,
    bool? isNew,
    TrackModel? track,
    String? type,
    IconData? icon,
    Color? iconColor,
    Color? bgColor,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      time: time ?? this.time,
      isNew: isNew ?? this.isNew,
      track: track ?? this.track,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      bgColor: bgColor ?? this.bgColor,
    );
  }
}

class NotificationsState {
  final List<NotificationModel> list;
  final bool isLoading;

  const NotificationsState({
    this.list = const [],
    this.isLoading = false,
  });

  NotificationsState copyWith({
    List<NotificationModel>? list,
    bool? isLoading,
  }) {
    return NotificationsState(
      list: list ?? this.list,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref _ref;

  NotificationsNotifier(this._ref) : super(const NotificationsState()) {
    // Initial fetch of notifications
    refreshNotifications();
  }

  Future<void> refreshNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final langs = _ref.read(selectedLanguagesProvider).value ?? ['hindi'];
      final repo = _ref.read(homeRepositoryProvider);
      
      final List<NotificationModel> newList = [];
      
      // 1. Welcome Notification
      newList.add(NotificationModel(
        id: 'system_welcome',
        title: 'Welcome to RaagaFlow 🌸',
        subtitle: 'Experience premium, high-res audio streaming tailored for you.',
        time: 'Just now',
        isNew: true,
        type: 'system',
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFFA78B71),
        bgColor: const Color(0xFF1A1410),
      ));
      
      // 2. Fetch trending for primary language
      if (langs.isNotEmpty) {
        final primaryLang = langs.first;
        try {
          final trendingTracks = await repo.getTrending(primaryLang);
          if (trendingTracks.isNotEmpty) {
            final topTrack = trendingTracks.first;
            newList.add(NotificationModel(
              id: 'trending_${primaryLang}_${topTrack.id}',
              title: 'Trending in ${primaryLang[0].toUpperCase()}${primaryLang.substring(1)} 🔥',
              subtitle: 'Listen to "${topTrack.title}" by ${topTrack.artist} - currently hot!',
              time: '5 min ago',
              isNew: true,
              track: topTrack,
              type: 'trending',
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFFFFD700),
              bgColor: const Color(0xFF1E1A0A),
            ));
          }
        } catch (e) {
          debugPrint('Error fetching trending for notification: $e');
        }
      }
      
      // 3. Fetch new releases for secondary language if available, otherwise primary
      final targetLang = langs.length > 1 ? langs[1] : (langs.isNotEmpty ? langs.first : 'hindi');
      try {
        final newTracks = await repo.getNewReleases(targetLang);
        if (newTracks.isNotEmpty) {
          final topNew = newTracks.first;
          newList.add(NotificationModel(
            id: 'new_release_${targetLang}_${topNew.id}',
            title: 'New Release in ${targetLang[0].toUpperCase()}${targetLang.substring(1)} 🌸',
            subtitle: '"${topNew.title}" by ${topNew.artist} just dropped! Stream now.',
            time: '15 min ago',
            isNew: true,
            track: topNew,
            type: 'release',
            icon: Icons.new_releases_rounded,
            iconColor: const Color(0xFFE48BA7),
            bgColor: const Color(0xFF2A1520),
          ));
        }
      } catch (e) {
        debugPrint('Error fetching releases for notification: $e');
      }
      
      // 4. Play Again history-based notification
      final history = _ref.read(libraryProvider).history;
      if (history.isNotEmpty) {
        final lastTrack = history.first;
        newList.add(NotificationModel(
          id: 'history_${lastTrack.id}',
          title: 'Enjoyed "${lastTrack.title}"? 🎧',
          subtitle: 'Tap to listen again to ${lastTrack.artist} and similar hits.',
          time: '1 hr ago',
          isNew: false,
          track: lastTrack,
          type: 'history',
          icon: Icons.playlist_add_rounded,
          iconColor: const Color(0xFF7EC8E3),
          bgColor: const Color(0xFF101E28),
        ));
      } else {
        // Fallback discovery
        newList.add(NotificationModel(
          id: 'system_discover',
          title: 'Daily Mix Ready ⚡',
          subtitle: 'Your personalized vibe playlist is ready for today.',
          time: '2 hrs ago',
          isNew: false,
          type: 'system',
          icon: Icons.speaker_rounded,
          iconColor: const Color(0xFF78909C),
          bgColor: const Color(0xFF111618),
        ));
      }
      
      state = NotificationsState(list: newList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void markAllAsRead() {
    state = state.copyWith(
      list: state.list.map((n) => n.copyWith(isNew: false)).toList(),
    );
  }

  void markAsRead(String id) {
    state = state.copyWith(
      list: state.list.map((n) => n.id == id ? n.copyWith(isNew: false) : n).toList(),
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final notifier = NotificationsNotifier(ref);

  // Auto-refresh when selected languages list shifts
  ref.listen(selectedLanguagesProvider, (prev, next) {
    notifier.refreshNotifications();
  });

  // Auto-refresh when history is added (to update history recommendation)
  ref.listen(libraryProvider.select((s) => s.history), (prev, next) {
    notifier.refreshNotifications();
  });

  // Auto-refresh when currently playing track changes
  ref.listen(playerProvider.select((s) => s.currentTrack), (prev, next) {
    notifier.refreshNotifications();
  });

  return notifier;
});
