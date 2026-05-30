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

    // Fast orbital loop for particles
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Deep breathing pulse for the ambient liquid background glow
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
        width: 320,
        height: 320,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ─── Layer 1: Ambient 3D Glowing Pulsing Aura ───
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final scale = 1.0 + (_pulseCtrl.value * 0.12);
                final opacity = 0.15 + (_pulseCtrl.value * 0.18);
                
                return Container(
                  width: 200 * scale,
                  height: 200 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: opacity),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ─── Layer 2: 3D Holographic Orbiting Gyroscope Rings ───
            AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(320, 320),
                  painter: _GyroscopePainter(
                    angle: _orbitCtrl.value * 2 * pi,
                    accentColor: AppColors.accent,
                    primaryColor: AppColors.primary,
                    tertiaryColor: AppColors.tertiary,
                    isDark: isDark,
                  ),
                );
              },
            ),

            // ─── Layer 3: Floating Hovering Album Art Card ───
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final hoverOffset = sin(_pulseCtrl.value * pi) * 6.0;
                
                return Transform.translate(
                  offset: Offset(0, -hoverOffset),
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        // Deep luxurious 3D drop shadow simulating hovering height
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.22),
                          blurRadius: 28,
                          spreadRadius: 2,
                          offset: Offset(0, 16 + hoverOffset),
                        ),
                        // Soft ambient glowing highlight
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          blurRadius: 16,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: widget.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const ShimmerBox(width: 170, height: 170),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surfaceContainerHigh,
                                child: Icon(Icons.music_note,
                                    size: 50, color: AppColors.textHint),
                              ),
                            ),
                          ),
                          // Subtle diagonal glass shimmer overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.08),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.05),
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
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

// Custom painter to draw beautiful 3D tilted gyroscope rings with moving glowing beads
class _GyroscopePainter extends CustomPainter {
  final double angle;
  final Color accentColor;
  final Color primaryColor;
  final Color tertiaryColor;
  final bool isDark;

  _GyroscopePainter({
    required this.angle,
    required this.accentColor,
    required this.primaryColor,
    required this.tertiaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw three gyroscopic rings (Inner, Middle, Outer) with 3D tilts
    // Ring 1 (Accent): radius 108, tilt X, Y
    _drawTiltedRing(
      canvas, 
      center, 
      radius: 106, 
      tiltX: 0.5, 
      tiltY: 0.35, 
      ringColor: accentColor.withValues(alpha: 0.25),
      beadColor: accentColor,
      beadAngle: angle * 1.2, // Speeds up
    );

    // Ring 2 (Primary): radius 124, tilt X, Y
    _drawTiltedRing(
      canvas, 
      center, 
      radius: 124, 
      tiltX: -0.45, 
      tiltY: -0.4, 
      ringColor: primaryColor.withValues(alpha: 0.2),
      beadColor: primaryColor,
      beadAngle: -angle * 0.8, // Reverse rotation
    );

    // Ring 3 (Tertiary): radius 142, tilt X, Y
    _drawTiltedRing(
      canvas, 
      center, 
      radius: 142, 
      tiltX: 0.6, 
      tiltY: -0.22, 
      ringColor: tertiaryColor.withValues(alpha: 0.15),
      beadColor: tertiaryColor,
      beadAngle: angle * 0.5, // Slow glide
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
  }) {
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Calculate tilted coordinates using 3D projection formulas
    final path = Path();
    const steps = 90;
    
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
    
    // Draw the 3D-angled glass ring path
    canvas.drawPath(path, ringPaint);

    // Draw the moving glowing bead along the path
    final beadOffset = center + _project3D(radius, beadAngle, tiltX, tiltY);
    
    final beadPaint = Paint()
      ..color = beadColor
      ..style = PaintingStyle.fill;

    // Glow backing shadow
    canvas.drawCircle(
      beadOffset,
      6.0,
      Paint()
        ..color = beadColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    
    // Core solid light bead
    canvas.drawCircle(beadOffset, 3.5, beadPaint);
  }

  // 3D mathematical projection of a circular orbit given a camera tilt X and Y
  Offset _project3D(double radius, double theta, double tiltX, double tiltY) {
    // 3D position on flat Z-plane
    final double x = radius * cos(theta);
    final double y = radius * sin(theta);
    final double z = 0.0;

    // Rotate around X-axis
    final double cosX = cos(tiltX);
    final double sinX = sin(tiltX);
    final double y1 = y * cosX - z * sinX;
    
    // Rotate around Y-axis
    final double cosY = cos(tiltY);
    final double sinY = sin(tiltY);
    final double x2 = x * cosY + y1 * sinY;

    // Simple isometric projection
    return Offset(x2, y1);
  }

  @override
  bool shouldRepaint(covariant _GyroscopePainter oldDelegate) =>
      oldDelegate.angle != angle || 
      oldDelegate.accentColor != accentColor || 
      oldDelegate.primaryColor != primaryColor;
}
