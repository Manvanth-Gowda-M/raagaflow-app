import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';

class EmptyStateView extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateView({
    super.key,
    required this.message,
    this.icon = Icons.music_off,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textHint, size: 48),
            const SizedBox(height: 12),
            Text(message,
                style: AppTextStyles.trackArtist, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
