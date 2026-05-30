import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SourceBadge extends StatelessWidget {
  final String source;

  const SourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (source) {
      'saavn'   => (AppColors.saavnBadge,   Icons.auto_awesome_rounded,  ''),
      'jamendo' => (AppColors.jamendoBadge, Icons.volunteer_activism_rounded, ''),
      'pixabay' => (AppColors.pixabayBadge, Icons.photo_filter_rounded,  ''),
      'youtube' => (AppColors.youtubeBadge, Icons.play_circle_rounded,   ''),
      _         => (AppColors.textHint,     Icons.music_note_rounded,    ''),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
