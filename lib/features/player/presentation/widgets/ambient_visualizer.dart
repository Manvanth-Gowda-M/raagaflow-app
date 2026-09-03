import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shimmer_track_tile.dart';

class AmbientVisualizer extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;

  const AmbientVisualizer({
    super.key,
    required this.imageUrl,
    required this.isPlaying,
  });

  @override
  State<AmbientVisualizer> createState() => _AmbientVisualizerState();
}

class _AmbientVisualizerState extends State<AmbientVisualizer>
    with TickerProviderStateMixin {
  late final AnimationController _orbitCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();

    // Orbital loop for 3D gyroscope rings and glowing satellite particles
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // Deep organic breathing pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    if (widget.isPlaying) {
      _orbitCtrl.repeat();
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AmbientVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _orbitCtrl.repeat();
        _pulseCtrl.repeat(reverse: true);
      } else {
        _orbitCtrl.stop();
        _pulseCtrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.background.computeLuminance() < 0.4;

    return Center(
      child: SizedBox(
        width: 330,
        height: 330,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ─── Layer 1: Ambient Liquid Background Aura ───
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final scale = 1.0 + (_pulseCtrl.value * 0.15);
                final opacity = 0.22 + (_pulseCtrl.value * 0.20);

                return Container(
                  width: 250 * scale,
                  height: 250 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: opacity),
                        AppColors.secondary.withValues(alpha: opacity * 0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                );
              },
            ),

            // ─── Layer 2: 3D Holographic Gyroscopic Orbits ───
            AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(330, 330),
                  painter: _GyroscopePainter(
                    angle: _orbitCtrl.value * 2 * pi,
                    accentColor: AppColors.accent,
                    secondaryColor: AppColors.secondary,
                    tertiaryColor: AppColors.tertiary,
                    isDark: isDark,
                  ),
                );
              },
            ),

            // ─── Layer 3: High-Res 3D Squircle Album Artwork ───
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final hoverOffset = sin(_pulseCtrl.value * pi) * 4.0;
                final scale = 0.985 + (_pulseCtrl.value * 0.025);

                return Transform.translate(
                  offset: Offset(0, -hoverOffset),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1.0,
                        ),
                        boxShadow: [
                          // Deep dimensional ambient drop shadow
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.25),
                            blurRadius: 36,
                            spreadRadius: 4,
                            offset: Offset(0, 18 + hoverOffset),
                          ),
                          // Colored ambient rim glow
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.35),
                            blurRadius: 32,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(27),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CachedNetworkImage(
                                imageUrl: widget.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const ShimmerBox(width: 230, height: 230, radius: 28),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surfaceContainerHigh,
                                  child: Icon(Icons.music_note_rounded,
                                      size: 60, color: AppColors.textHint),
                                ),
                              ),
                            ),
                            // Subtle glass sheen reflection overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.12),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.15),
                                    ],
                                    stops: const [0.0, 0.45, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GyroscopePainter extends CustomPainter {
  final double angle;
  final Color accentColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final bool isDark;

  _GyroscopePainter({
    required this.angle,
    required this.accentColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Ring 1 (Inner Accent Glow): radius 136
    _drawTiltedRing(
      canvas,
      center,
      radius: 136,
      tiltX: 0.55,
      tiltY: 0.35,
      ringColor: accentColor.withValues(alpha: 0.35),
      beadColor: accentColor,
      beadAngle: angle * 1.2,
      beadRadius: 4.5,
    );

    // Ring 2 (Middle Secondary Coral): radius 150
    _drawTiltedRing(
      canvas,
      center,
      radius: 150,
      tiltX: -0.45,
      tiltY: -0.40,
      ringColor: secondaryColor.withValues(alpha: 0.30),
      beadColor: secondaryColor,
      beadAngle: -angle * 0.9,
      beadRadius: 4.0,
    );

    // Ring 3 (Outer Tertiary Aqua/Gold): radius 162
    _drawTiltedRing(
      canvas,
      center,
      radius: 162,
      tiltX: 0.65,
      tiltY: -0.25,
      ringColor: tertiaryColor.withValues(alpha: 0.25),
      beadColor: tertiaryColor,
      beadAngle: angle * 0.6,
      beadRadius: 3.5,
    );
  }

  void _drawTiltedRing(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double tiltX,
    required double tiltY,
    required Color ringColor,
    required Color beadColor,
    required double beadAngle,
    required double beadRadius,
  }) {
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final glowPaint = Paint()
      ..color = ringColor.withValues(alpha: ringColor.a * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;

    final path = Path();
    const steps = 36; // 36 steps provides smooth circle at 120fps with minimal GPU overhead

    for (int i = 0; i <= steps; i++) {
      final t = (i / steps) * 2 * pi;
      final point = _project3D(radius, t, tiltX, tiltY);
      final offset = center + point;
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, ringPaint);

    // Satellite Bead
    final beadOffset = center + _project3D(radius, beadAngle, tiltX, tiltY);

    // Satellite Diffuse Halo
    canvas.drawCircle(
      beadOffset,
      beadRadius * 1.8,
      Paint()..color = beadColor.withValues(alpha: 0.35),
    );

    // Satellite Core
    canvas.drawCircle(
      beadOffset,
      beadRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      beadOffset,
      beadRadius,
      Paint()
        ..color = beadColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  Offset _project3D(double radius, double theta, double tiltX, double tiltY) {
    final double x = radius * cos(theta);
    final double y = radius * sin(theta);
    const double z = 0.0;

    final double cosX = cos(tiltX);
    final double sinX = sin(tiltX);
    final double y1 = y * cosX - z * sinX;

    final double cosY = cos(tiltY);
    final double sinY = sin(tiltY);
    final double x2 = x * cosY + y1 * sinY;

    return Offset(x2, y1);
  }

  @override
  bool shouldRepaint(covariant _GyroscopePainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.secondaryColor != secondaryColor;
}
