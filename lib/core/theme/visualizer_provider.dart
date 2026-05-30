import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/hive_service.dart';

enum VisualizerStyle {
  classic,
  vinyl,
  ambient,
}

class VisualizerNotifier extends Notifier<VisualizerStyle> {
  static const _visualizerKey = 'selected_visualizer_style';

  @override
  VisualizerStyle build() {
    final settingsBox = HiveService.settings;
    final savedIndex = settingsBox.get(_visualizerKey, defaultValue: null);
    if (savedIndex != null && savedIndex is int && savedIndex >= 0 && savedIndex < VisualizerStyle.values.length) {
      return VisualizerStyle.values[savedIndex];
    }
    // Default to classic visualizer
    return VisualizerStyle.classic;
  }

  void setStyle(VisualizerStyle style) {
    state = style;
    HiveService.settings.put(_visualizerKey, style.index);
  }
}

final visualizerProvider = NotifierProvider<VisualizerNotifier, VisualizerStyle>(() {
  return VisualizerNotifier();
});
