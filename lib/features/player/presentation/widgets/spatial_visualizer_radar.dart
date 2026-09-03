import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/spatial_audio_provider.dart';

/// Interactive 3D Spatial Radar Visualizer.
///
/// Displays real-time sound coordinate trajectory, distance rings, listener orientation,
/// dynamic particle trail, and allows live touch-and-drag manual sound positioning.
class SpatialVisualizerRadar extends ConsumerStatefulWidget {
  final double size;

  const SpatialVisualizerRadar({
    super.key,
    this.size = 220,
  });

  @override
  ConsumerState<SpatialVisualizerRadar> createState() => _SpatialVisualizerRadarState();
}

class _SpatialVisualizerRadarState extends ConsumerState<SpatialVisualizerRadar> {
  final List<Offset> _trailHistory = [];
  static const int _maxTrailLength = 18;

  @override
  Widget build(BuildContext context) {
    final spatialState = ref.watch(spatialAudioProvider);
    final telemetry = spatialState.telemetry;
    final isEnabled = spatialState.isEnabled && !spatialState.isBypassed;

    // Convert Cartesian [-1.5..1.5] to widget local pixel offsets
    final double halfSize = widget.size / 2;
    // Map: x (-1.5 to 1.5) -> (0 to size), y (-1.5 to 1.5) -> inverted y (size to 0) because Front is top
    final double soundPixelX = halfSize + (telemetry.x / 1.5) * (halfSize * 0.85);
    final double soundPixelY = halfSize - (telemetry.y / 1.5) * (halfSize * 0.85);

    final currentPoint = Offset(soundPixelX, soundPixelY);
    if (isEnabled) {
      _trailHistory.add(currentPoint);
      if (_trailHistory.length > _maxTrailLength) {
        _trailHistory.removeAt(0);
      }
    } else {
      _trailHistory.clear();
    }

    return Center(
      child: GestureDetector(
        onPanStart: (details) => _handleTouch(details.localPosition, halfSize),
        onPanUpdate: (details) => _handleTouch(details.localPosition, halfSize),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.35),
            border: Border.all(
              color: isEnabled
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.divider.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: CustomPaint(
            painter: _RadarCustomPainter(
              soundPos: currentPoint,
              trail: List.from(_trailHistory),
              isEnabled: isEnabled,
              azimuthDegrees: telemetry.azimuthDegrees,
              distance: telemetry.distance,
            ),
          ),
        ),
      ),
    );
  }

  void _handleTouch(Offset localPos, double halfSize) {
    // Convert touch pixel coordinates back to normalized Cartesian [-1.5, 1.5]
    final double normX = ((localPos.dx - halfSize) / (halfSize * 0.85)) * 1.5;
    final double normY = -((localPos.dy - halfSize) / (halfSize * 0.85)) * 1.5; // inverted for Front

    ref.read(spatialAudioProvider.notifier).setManualPosition(normX, normY);
  }
}

class _RadarCustomPainter extends CustomPainter {
  final Offset soundPos;
  final List<Offset> trail;
  final bool isEnabled;
  final double azimuthDegrees;
  final double distance;

  _RadarCustomPainter({
    required this.soundPos,
    required this.trail,
    required this.isEnabled,
    required this.azimuthDegrees,
    required this.distance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 * 0.88;

    // ─── 1. Concentric Distance Orbit Rings ──────────────────────────────────
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rings = [0.35, 0.65, 1.0];
    for (int i = 0; i < rings.length; i++) {
      final r = maxRadius * rings[i];
      ringPaint.color = isEnabled
          ? AppColors.accent.withValues(alpha: 0.08 + (i * 0.05))
          : AppColors.divider.withValues(alpha: 0.08);
      canvas.drawCircle(center, r, ringPaint);
    }

    // ─── 2. Crosshair Grid & Cardinal Markers ────────────────────────────────
    final axisPaint = Paint()
      ..color = isEnabled
          ? AppColors.accent.withValues(alpha: 0.15)
          : AppColors.divider.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;

    // Vertical line (Front - Back)
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), axisPaint);
    // Horizontal line (Left - Right)
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), axisPaint);

    // Cardinal Labels
    _drawLabel(canvas, 'FRONT', Offset(center.dx, center.dy - maxRadius - 10), isEnabled);
    _drawLabel(canvas, 'BACK', Offset(center.dx, center.dy + maxRadius + 10), isEnabled);
    _drawLabel(canvas, 'L', Offset(center.dx - maxRadius - 10, center.dy), isEnabled);
    _drawLabel(canvas, 'R', Offset(center.dx + maxRadius + 10, center.dy), isEnabled);

    // ─── 3. Center Listener Icon ─────────────────────────────────────────────
    final listenerPaint = Paint()
      ..color = isEnabled ? AppColors.accent : AppColors.textHint
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5.5, listenerPaint);

    // Subtle listener glow
    if (isEnabled) {
      final glowPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, 8.0, glowPaint);
    }

    // ─── 4. Motion Particle Trail ────────────────────────────────────────────
    if (trail.isNotEmpty && isEnabled) {
      for (int i = 0; i < trail.length; i++) {
        final double opacity = (i / trail.length) * 0.65;
        final double trailRadius = 2.0 + (i / trail.length) * 4.0;
        final trailPaint = Paint()
          ..color = AppColors.accent.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(trail[i], trailRadius, trailPaint);
      }
    }

    // ─── 5. Active Sound Particle Orb ────────────────────────────────────────
    final soundOrbPaint = Paint()
      ..color = isEnabled ? Colors.white : AppColors.textHint
      ..style = PaintingStyle.fill;

    if (isEnabled) {
      // Outer luminous pulse ring
      final pulsePaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(soundPos, 12.0, pulsePaint);

      // Core glow
      final orbGlow = Paint()
        ..color = AppColors.accent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(soundPos, 8.0, orbGlow);
    }

    canvas.drawCircle(soundPos, isEnabled ? 6.0 : 4.0, soundOrbPaint);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, bool active) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: active ? AppColors.accent.withValues(alpha: 0.75) : AppColors.textHint.withValues(alpha: 0.4),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarCustomPainter oldDelegate) {
    return oldDelegate.soundPos != soundPos ||
        oldDelegate.trail.length != trail.length ||
        oldDelegate.isEnabled != isEnabled;
  }
}
