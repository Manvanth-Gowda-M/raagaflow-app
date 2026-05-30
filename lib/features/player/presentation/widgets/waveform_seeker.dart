import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WaveformSeeker extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final String trackTitle;
  final bool isPlaying;
  final Function(Duration) onSeek;
  final int barCount;

  const WaveformSeeker({
    super.key,
    required this.position,
    required this.duration,
    required this.trackTitle,
    required this.isPlaying,
    required this.onSeek,
    this.barCount = 42,
  });

  @override
  State<WaveformSeeker> createState() => _WaveformSeekerState();
}

class _WaveformSeekerState extends State<WaveformSeeker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late List<double> _baseHeights;

  @override
  void initState() {
    super.initState();
    
    // Continuous loop controller for fluid real-time wave oscillations
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _generateBaseHeights();

    if (widget.isPlaying) {
      _waveCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(WaveformSeeker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trackTitle != oldWidget.trackTitle) {
      _generateBaseHeights();
    }
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _waveCtrl.repeat();
      } else {
        _waveCtrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  // Generates a deterministic list of heights based on the track title
  void _generateBaseHeights() {
    final random = Random(widget.trackTitle.hashCode);
    _baseHeights = List.generate(widget.barCount, (index) {
      final centerFactor = 1.0 - ((index - widget.barCount / 2).abs() / (widget.barCount / 2));
      final base = 0.2 + 0.7 * centerFactor;
      final variance = random.nextDouble() * 0.2 - 0.1;
      return (base + variance).clamp(0.15, 1.0);
    });
  }

  void _handleInteraction(BuildContext context, BoxConstraints constraints, double localX) {
    if (widget.duration.inMilliseconds <= 0) return;
    
    final width = constraints.maxWidth;
    final percent = (localX / width).clamp(0.0, 1.0);
    final targetMs = (percent * widget.duration.inMilliseconds).round();
    widget.onSeek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleInteraction(context, constraints, details.localPosition.dx),
          onHorizontalDragUpdate: (details) => _handleInteraction(context, constraints, details.localPosition.dx),
          child: Container(
            height: 60,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: AnimatedBuilder(
              animation: _waveCtrl,
              builder: (context, child) {
                final wavePhase = _waveCtrl.value * 2 * pi;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(widget.barCount, (index) {
                    final barPercent = index / widget.barCount;
                    final isPlayed = barPercent <= progress;
                    
                    // Base fingerprint height
                    final baseHeight = _baseHeights[index];

                    // Synthesize dynamic micro-oscillations when playing to mimic live frequencies
                    double waveOffset = 0.0;
                    if (widget.isPlaying) {
                      // Combined sine waves at different frequencies creates a realistic fluid organic bouncing wave
                      waveOffset = sin(wavePhase * 2 + index * 0.6) * cos(wavePhase - index * 0.3) * 0.22;
                      
                      // Dampen/scale waves slightly near the edges for neatness
                      final edgeDampening = 1.0 - ((index - widget.barCount / 2).abs() / (widget.barCount / 2));
                      waveOffset *= edgeDampening;
                    }

                    final dynamicHeight = (baseHeight + waveOffset).clamp(0.1, 1.0);

                    // Active accent color (played) or transparent secondary (unplayed)
                    final color = isPlayed
                        ? AppColors.accent
                        : AppColors.textHint.withValues(alpha: 0.3);

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        height: 50.0 * dynamicHeight,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
