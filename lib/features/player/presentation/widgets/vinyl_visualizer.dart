import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shimmer_track_tile.dart';

class VinylVisualizer extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;

  const VinylVisualizer({
    super.key,
    required this.imageUrl,
    required this.isPlaying,
  });

  @override
  State<VinylVisualizer> createState() => _VinylVisualizerState();
}

class _VinylVisualizerState extends State<VinylVisualizer>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _armCtrl;
  late final Animation<double> _armRotation;

  @override
  void initState() {
    super.initState();
    
    // Smooth spinning record controller
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    // Smooth tonearm transition controller (slow, heavy mechanical feel)
    _armCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Angle of tonearm (in radians).
    // Rest position: 0.0 radians (rests off the record on the side)
    // Playing position: -0.28 radians (pivots left to rest on the outer record grooves)
    _armRotation = Tween<double>(begin: 0.0, end: -0.28).animate(
      CurvedAnimation(
        parent: _armCtrl,
        curve: Curves.easeInOutCubic,
      ),
    );

    if (widget.isPlaying) {
      _spinCtrl.repeat();
      _armCtrl.forward();
    }
  }

  @override
  void didUpdateWidget(VinylVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _spinCtrl.repeat();
        _armCtrl.forward();
      } else {
        _spinCtrl.stop();
        _armCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _armCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.background.computeLuminance() < 0.4;
    
    // Neumorphic color palette
    final shadowColorLight = isDark 
        ? Colors.white.withValues(alpha: 0.04) 
        : Colors.white;
    final shadowColorDark = isDark 
        ? Colors.black.withValues(alpha: 0.65) 
        : const Color(0xFFE5DCD7).withValues(alpha: 0.8);

    return Center(
      child: SizedBox(
        width: 320,
        height: 320,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ─── Layer 1: Skeuomorphic Turntable Base Platter Well ───
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: shadowColorDark,
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(10, 10),
                  ),
                  BoxShadow(
                    color: shadowColorLight,
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(-8, -8),
                  ),
                ],
              ),
              child: Center(
                // Recessed deep inner well
                child: Container(
                  width: 276,
                  height: 276,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.background,
                        AppColors.surfaceContainerLow,
                      ],
                      center: Alignment.center,
                      radius: 0.85,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(2, 2),
                      ),
                      BoxShadow(
                        color: shadowColorLight.withValues(alpha: isDark ? 0.08 : 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Layer 2: Spinning Vinyl Record Platter ───
            RotationTransition(
              turns: _spinCtrl,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF141416),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Conforming grooves inside the thin black vinyl rim
                    for (int i = 1; i <= 3; i++)
                      Container(
                        width: 240.0 - (i * 10),
                        height: 240.0 - (i * 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.035),
                            width: 1,
                          ),
                        ),
                      ),
                    
                    // Center Album Cover Label (Vastly enlarged matching references!)
                    Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF141416),
                          width: 3.5,
                        ),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerBox(width: 168, height: 168),
                          errorWidget: (_, __, ___) => Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Layer 3: Fixed Reflective Sheen (Stationary Gloss Overlay) ───
            IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.01),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.01),
                      Colors.white.withValues(alpha: 0.07),
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // ─── Layer 4: Center Silver Metal Spindle Pin ───
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFF3F3F5),
                    Color(0xFF9E9EB2),
                    Color(0xFF50505A),
                  ],
                  center: Alignment.topLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),

            // ─── Layer 5: Clean Static Pivot Base (Outside Platter, Top Right) ───
            Positioned(
              top: 36,
              right: 36,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColorDark.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(1, 2),
                    ),
                    BoxShadow(
                      color: shadowColorLight.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(-1, -1),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFFEBEBEB),
                          Color(0xFFB5B5BE),
                          Color(0xFF65656F),
                        ],
                        center: Alignment.topLeft,
                      ),
                    ),
                    child: Center(
                      // Center metallic dot
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4A4A50),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Layer 6: Dynamic Pivot Arm (Only Arm Rotates around the Base center) ───
            Positioned(
              top: 52, // Center of pivot base
              right: 52, // Center of pivot base
              child: AnimatedBuilder(
                animation: _armRotation,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.topRight, // Pivot perfectly around the base top-right corner
                    transform: Matrix4.rotationZ(_armRotation.value),
                    child: SizedBox(
                      width: 80,
                      height: 155,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Custom Painter to draw a clean, thin, elegant curved arm and stylus head
                          Positioned(
                            top: 0,
                            right: 0,
                            child: CustomPaint(
                              size: const Size(80, 155),
                              painter: _TonearmPainter(
                                armColor: isDark 
                                    ? Colors.white.withValues(alpha: 0.8) 
                                    : AppColors.textSecondary,
                                accentColor: AppColors.accent,
                              ),
                            ),
                          ),
                          
                          // Resting fork/post (visible only when arm is in resting state)
                          if (_armRotation.value > -0.05)
                            Positioned(
                              bottom: 30,
                              right: 12,
                              child: Container(
                                width: 8,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.textHint.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Draw a very sleek, thin, curved arm rod and a stylus head pointing inwards
class _TonearmPainter extends CustomPainter {
  final Color armColor;
  final Color accentColor;

  _TonearmPainter({
    required this.armColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final armPaint = Paint()
      ..color = armColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 // Much thinner and elegant
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Start exactly at the pivot (top right corner of the arm container)
    path.moveTo(size.width, 0);
    
    // Draw a premium gentle curve down and leftwards around the vinyl edge
    path.cubicTo(
      size.width - 2, size.height * 0.35,
      size.width - 4, size.height * 0.70,
      size.width * 0.35, size.height * 0.86,
    );
    
    // Final short link straight into the angled headshell cartridge
    path.lineTo(size.width * 0.16, size.height * 0.96);

    // Subtle drop shadow under the arm
    canvas.save();
    canvas.translate(2, 3);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Paint the elegant metal rod
    canvas.drawPath(path, armPaint);

    // ─── Angled Headshell & Cartridge (Needle) ───
    final tipX = size.width * 0.16;
    final tipY = size.height * 0.96;

    final cartridgePaint = Paint()
      ..color = armColor
      ..style = PaintingStyle.fill;

    final accentNeedleDot = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(tipX, tipY);
    // Align headshell cartridge pointing along the grooves
    canvas.rotate(-0.4); 

    // Cartridge shadow
    canvas.drawRect(
      const Rect.fromLTWH(-5, -2, 10, 18),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
    
    // Stylus cartridge body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, -3, 12, 20),
        const Radius.circular(3),
      ),
      cartridgePaint,
    );
    
    // Premium stylus indicator light dot
    canvas.drawCircle(
      const Offset(0, 8),
      2.0,
      accentNeedleDot,
    );
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TonearmPainter oldDelegate) => 
      oldDelegate.armColor != armColor || oldDelegate.accentColor != accentColor;
}
