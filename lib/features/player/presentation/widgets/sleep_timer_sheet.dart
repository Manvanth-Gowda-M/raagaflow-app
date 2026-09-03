import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/sleep_timer_provider.dart';

class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SleepTimerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sleepTimerProvider);
    final notifier = ref.read(sleepTimerProvider.notifier);

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
            Row(
              children: [
                Icon(Icons.bedtime_rounded, color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                Text('Sleep Timer', style: AppTextStyles.headline2),
                const Spacer(),
                if (timerState.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timerState.formattedRemaining,
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Music will gradually fade out and pause automatically.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // Quick duration options
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildOptionChip(context, '15 Minutes', const Duration(minutes: 15), timerState, notifier),
                _buildOptionChip(context, '30 Minutes', const Duration(minutes: 30), timerState, notifier),
                _buildOptionChip(context, '45 Minutes', const Duration(minutes: 45), timerState, notifier),
                _buildOptionChip(context, '60 Minutes', const Duration(minutes: 60), timerState, notifier),
                _buildEndOfTrackChip(context, timerState, notifier),
              ],
            ),
            const SizedBox(height: 20),
            if (timerState.isActive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    notifier.cancelTimer();
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.timer_off_outlined, color: AppColors.secondary, size: 18),
                  label: Text('Turn Off Timer', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.secondary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip(
    BuildContext context,
    String label,
    Duration duration,
    SleepTimerState state,
    SleepTimerNotifier notifier,
  ) {
    final isSelected = state.isActive && !state.endOfTrack && state.totalDuration == duration;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        notifier.setTimer(duration, fadeOut: true);
        Navigator.pop(context);
      },
      selectedColor: AppColors.accent,
      backgroundColor: AppColors.surfaceContainerHigh,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.accent : AppColors.divider.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildEndOfTrackChip(
    BuildContext context,
    SleepTimerState state,
    SleepTimerNotifier notifier,
  ) {
    final isSelected = state.isActive && state.endOfTrack;
    return ChoiceChip(
      label: const Text('End of Track'),
      selected: isSelected,
      onSelected: (_) {
        notifier.setEndOfTrack();
        Navigator.pop(context);
      },
      selectedColor: AppColors.accent,
      backgroundColor: AppColors.surfaceContainerHigh,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.accent : AppColors.divider.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
