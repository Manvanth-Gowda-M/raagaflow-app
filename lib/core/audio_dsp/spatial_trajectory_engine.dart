import 'dart:math' as math;
import 'spatial_math.dart';
import 'spatial_models.dart';

/// Kinematic 3D Trajectory Engine for 8D Audio Movement.
///
/// Computes continuous, mathematically smooth spatial coordinates $(x, y, z)$
/// across various trajectory geometries (Orbit, Lemniscate, Lissajous, Cinematic, Manual).
class SpatialTrajectoryEngine {
  double _elapsedSeconds = 0.0;
  double _currentX = 0.0;
  double _currentY = 1.0;
  double _currentZ = 0.0;

  // Track-specific deterministic seed parameters
  double _seedPhaseOffset = 0.0;
  double _seedWobbleRate = 0.0;

  // Manual interactive target coordinates
  double _targetManualX = 0.0;
  double _targetManualY = 1.0;
  double _targetManualZ = 0.0;

  SpatialTrajectoryEngine();

  /// Initializes or resets deterministic movement patterns based on a track's unique ID.
  ///
  /// Guarantees that the same track will have the same organic spatial movement every time it plays.
  void setTrackSeed(String trackId) {
    if (trackId.isEmpty) {
      _seedPhaseOffset = 0.0;
      _seedWobbleRate = 0.0;
      return;
    }
    int hash = 0;
    for (int i = 0; i < trackId.length; i++) {
      hash = (hash * 31 + trackId.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    // Deterministic phase offset between 0 and 2*pi
    _seedPhaseOffset = (hash % 1000) / 1000.0 * 2.0 * math.pi;
    // Subtle organic harmonic wobble rate (±10% speed variance)
    _seedWobbleRate = (((hash >> 10) % 100) / 100.0 - 0.5) * 0.15;
  }

  /// Sets interactive manual sound coordinates when in Manual Mode.
  void setManualPosition(double x, double y, [double z = 0.0]) {
    _targetManualX = x.clamp(-1.5, 1.5);
    _targetManualY = y.clamp(-1.5, 1.5);
    _targetManualZ = z.clamp(-1.0, 1.0);
  }

  /// Resets internal trajectory clock and position to front-center.
  void reset() {
    _elapsedSeconds = 0.0;
    _currentX = 0.0;
    _currentY = 1.0;
    _currentZ = 0.0;
  }

  /// Steps the kinematic trajectory forward by [deltaSeconds] and returns the computed 3D Cartesian coordinates.
  CartesianCoords update(double deltaSeconds, SpatialParameters params, {double musicalEnergy = 0.5}) {
    _elapsedSeconds += deltaSeconds;

    final double intensity = params.intensity.clamp(0.0, 1.0);
    final double radius = params.orbitRadius * intensity;
    final double depthScale = params.depth.clamp(0.1, 1.0);
    final double baseSpeed = params.speedRadPerSec * (1.0 + _seedWobbleRate);

    // Dynamic music energy modulation (subtle ±10% speed/radius breathing with beat)
    final double effectiveSpeed = baseSpeed * (0.95 + 0.10 * musicalEnergy);
    final double t = (_elapsedSeconds * effectiveSpeed) + _seedPhaseOffset;

    double targetX = 0.0;
    double targetY = 1.0;
    double targetZ = 0.0;

    switch (params.trajectory) {
      case TrajectoryType.orbit:
        // Smooth circular 360° orbit: x = sin(t), y = cos(t)
        targetX = radius * math.sin(t);
        targetY = radius * math.cos(t) * depthScale;
        targetZ = (radius * 0.2) * math.sin(t * 0.5);
        break;

      case TrajectoryType.vocalBeatSplit:
        // Left Vocals / Right Beats dual cross-movement:
        // Lingers at the ears with a smooth sinusoidal transition through the cranium
        final double sinVal = math.sin(t);
        final double curve = (sinVal >= 0 ? 1.0 : -1.0) * math.pow(sinVal.abs(), 0.75);
        targetX = radius * curve;
        targetY = radius * math.cos(t) * depthScale * 0.6;
        targetZ = (radius * 0.25) * math.sin(t * 2.0);
        break;

      case TrajectoryType.figureEight:
        // Lemniscate of Bernoulli path
        // Passes smoothly across listener from front-left to back-right in an infinity loop
        targetX = radius * math.sin(t);
        targetY = (radius * math.sin(2.0 * t) * 0.6) * depthScale;
        targetZ = (radius * 0.15) * math.cos(t);
        break;

      case TrajectoryType.dreamSpace:
        // Dual-harmonic Lissajous 3:2 curve with smooth non-repeating organic drift
        targetX = radius * math.sin(t * 0.75);
        targetY = (radius * math.cos(t * 0.50 + math.pi / 4.0)) * depthScale;
        targetZ = (radius * 0.3) * math.sin(t * 0.25);
        break;

      case TrajectoryType.cinematic:
        // Ultra-slow grand spatial sweep with subtle evolving distance expansion
        // Distance breathes between 0.7*radius and 1.15*radius over ~45-90 seconds
        final double distanceBreathing = 0.85 + 0.25 * math.sin(t * 0.2);
        targetX = radius * distanceBreathing * math.sin(t);
        targetY = radius * distanceBreathing * math.cos(t) * depthScale;
        targetZ = (radius * 0.1) * math.cos(t * 0.3);
        break;

      case TrajectoryType.manual:
        targetX = _targetManualX;
        targetY = _targetManualY;
        targetZ = _targetManualZ;
        break;
    }

    // Critically damped exponential smoothing (tau ≈ 40ms) to ensure ZERO clicks or sudden jumps
    final double smoothingFactor = 1.0 - math.exp(-deltaSeconds / 0.040);
    _currentX += (targetX - _currentX) * smoothingFactor;
    _currentY += (targetY - _currentY) * smoothingFactor;
    _currentZ += (targetZ - _currentZ) * smoothingFactor;

    return CartesianCoords(x: _currentX, y: _currentY, z: _currentZ);
  }
}
