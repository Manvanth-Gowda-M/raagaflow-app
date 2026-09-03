import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MiniEqualizerBars extends StatefulWidget {
  final bool isPlaying;
  final Color? color;
  final double size;

  const MiniEqualizerBars({
    super.key,
    required this.isPlaying,
    this.color,
    this.size = 20,
  });

  @override
  State<MiniEqualizerBars> createState() => _MiniEqualizerBarsState();
}

class _MiniEqualizerBarsState extends State<MiniEqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isPlaying) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MiniEqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
        _ctrl.animateTo(0.2, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = widget.color ?? AppColors.accent;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        // 3 bar heights with staggered phase offsets
        final h1 = widget.isPlaying ? 0.3 + 0.7 * ((t * 2.5) % 1.0) : 0.3;
        final h2 = widget.isPlaying ? 0.4 + 0.6 * ((t * 1.8 + 0.4) % 1.0) : 0.5;
        final h3 = widget.isPlaying ? 0.2 + 0.8 * ((t * 2.2 + 0.7) % 1.0) : 0.2;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(h1, barColor),
              _buildBar(h2, barColor),
              _buildBar(h3, barColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(double heightFactor, Color color) {
    return Container(
      width: (widget.size / 3) - 2.5,
      height: (widget.size * heightFactor.clamp(0.2, 1.0)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
