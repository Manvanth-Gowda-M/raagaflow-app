import 'dart:math' as math;

/// Core Psychoacoustic & Spatial Mathematics Library for RaagaFlow 8D Audio Engine.
///
/// Implements standard binaural localization equations, Woodworth's spherical
/// head model for Interaural Time Difference (ITD), head-shadow Interaural
/// Level Difference (ILD), distance air-absorption roll-off, Mid-Side decomposition,
/// and real-time stereo correlation analysis.
class SpatialMath {
  SpatialMath._();

  /// Speed of sound in air at 20°C (m/s).
  static const double speedOfSound = 343.0;

  /// Average human head radius (meters) — ~8.75 cm.
  static const double headRadius = 0.0875;

  /// Maximum human ITD at ±90° azimuth (~650 microseconds).
  static const double maxItdSeconds = (headRadius / speedOfSound) * (1.0 + math.pi / 2.0);

  // ─── Coordinate Transformations ───────────────────────────────────────────

  /// Converts 3D Cartesian coordinates (x: Left/Right [-1,1], y: Front/Back [-1,1], z: Up/Down [-1,1])
  /// into Spherical coordinates [azimuthRadians, distance, elevationRadians].
  ///
  /// - Azimuth: 0 = Front, +pi/2 = Right, -pi/2 = Left, ±pi = Behind.
  /// - Distance: normalized Euclidean distance [0.0, 1.414+].
  /// - Elevation: 0 = Horizontal plane, +pi/2 = Directly above, -pi/2 = Directly below.
  static SphericalCoords cartesianToSpherical(double x, double y, [double z = 0.0]) {
    final double distance = math.sqrt(x * x + y * y + z * z);
    if (distance < 0.0001) {
      return const SphericalCoords(azimuth: 0.0, distance: 0.0, elevation: 0.0);
    }
    // Azimuth: angle in horizontal plane relative to Front (y > 0)
    // atan2(x, y) gives 0 at (0,1) [Front], +pi/2 at (1,0) [Right], -pi/2 at (-1,0) [Left], pi at (0,-1) [Back]
    final double azimuth = math.atan2(x, y);

    // Elevation: angle above/below horizontal plane
    final double horizontalDist = math.sqrt(x * x + y * y);
    final double elevation = math.atan2(z, horizontalDist);

    return SphericalCoords(
      azimuth: azimuth,
      distance: distance,
      elevation: elevation,
    );
  }

  /// Converts Spherical coordinates (azimuth, distance, elevation) back to Cartesian (x, y, z).
  static CartesianCoords sphericalToCartesian(double azimuth, double distance, [double elevation = 0.0]) {
    final double cosElev = math.cos(elevation);
    final double x = distance * math.sin(azimuth) * cosElev;
    final double y = distance * math.cos(azimuth) * cosElev;
    final double z = distance * math.sin(elevation);
    return CartesianCoords(x: x, y: y, z: z);
  }

  // ─── Psychoacoustic Cues (ITD & ILD) ──────────────────────────────────────

  /// Calculates the Woodworth Interaural Time Difference (ITD) in seconds for a given azimuth angle.
  ///
  /// Woodworth formula: Δt = (a / c) * (sin|θ| + |θ|)
  /// Returns a signed time difference: positive = right ear delayed (sound is on left),
  /// negative = left ear delayed (sound is on right).
  static double calculateWoodworthITD(double azimuthRadians) {
    final double absTheta = azimuthRadians.abs();
    // Wrap to [0, pi]
    final double theta = absTheta > math.pi ? (2 * math.pi - absTheta) : absTheta;
    final double itdMag = (headRadius / speedOfSound) * (math.sin(theta) + theta);
    return (azimuthRadians >= 0) ? -itdMag : itdMag;
  }

  /// Calculates the asymmetric pinna and head-shadow gain factors (in dB) for Left and Right ears.
  ///
  /// The contralateral ear (shadowed ear) receives an attenuation in high frequencies
  /// up to -6dB to -8dB, while the ipsilateral ear receives a subtle high-frequency boost.
  static StereoGain calculateBinauralGains(double azimuthRadians, double distance) {
    // Normalised distance attenuation curve (perceptual 1 / (1 + 0.4*d))
    final double distAtten = 1.0 / (1.0 + 0.45 * distance.clamp(0.0, 3.0));

    // Pan factor: sin(azimuth) ranges from -1.0 (hard left) to +1.0 (hard right)
    final double panFactor = math.sin(azimuthRadians);

    // Constant-power sinusoidal panning law with center preservation
    final double angle = (panFactor + 1.0) * (math.pi / 4.0); // 0 (left) to pi/2 (right)
    final double gainLeft = math.cos(angle) * distAtten;
    final double gainRight = math.sin(angle) * distAtten;

    return StereoGain(left: gainLeft, right: gainRight);
  }

  /// Calculates the distance-dependent air-absorption low-pass filter cutoff frequency in Hz.
  ///
  /// Close sounds maintain full 20kHz sparkle.
  /// Distant sounds experience natural atmospheric high-frequency damping (down to ~8.5kHz).
  static double calculateAirAbsorptionCutoff(double distance) {
    // Distance normalized [0.0 (near) to 2.0 (far)]
    final double d = distance.clamp(0.0, 2.5);
    // Exponential roll-off curve
    return 20000.0 * math.exp(-0.35 * d);
  }

  /// Calculates front/back acoustic contrast.
  ///
  /// Sounds positioned behind the listener (y < 0) have reduced high-mid energy (around 3kHz–6kHz)
  /// due to human pinna acoustic reflection blocking.
  static double calculateRearPinnaDamping(double y) {
    if (y >= 0.0) return 1.0; // In front: 0dB damping
    // Behind: gentle attenuation factor down to 0.75 (-2.5dB)
    return 1.0 + (y * 0.25).clamp(-0.25, 0.0);
  }

  // ─── Mid/Side & Stereo Processing ─────────────────────────────────────────

  /// Decomposes stereo Left/Right into Mid (center mono) and Side (stereo difference).
  ///
  /// Mid = (L + R) / 2
  /// Side = (L - R) / 2
  static MidSide encodeMidSide(double left, double right) {
    return MidSide(
      mid: (left + right) * 0.5,
      side: (left - right) * 0.5,
    );
  }

  /// Reconstructs Left and Right from Mid and Side with parametric stereo width.
  ///
  /// Width = 0.0 (Pure Mono)
  /// Width = 1.0 (Natural Stereo)
  /// Width = 2.0 (Ultra-Wide Spatial Field)
  static StereoGain decodeMidSide(double mid, double side, double width) {
    final double effectiveSide = side * width;
    return StereoGain(
      left: mid + effectiveSide,
      right: mid - effectiveSide,
    );
  }

  /// Computes the Pearson stereo correlation coefficient (rho) between two audio channel buffers.
  ///
  /// rho = sum(L * R) / sqrt(sum(L^2) * sum(R^2))
  /// - +1.0 = 100% Mono / In-phase (Perfect mono compatibility)
  /// - 0.0 = True decorrelated stereo / wide soundstage
  /// - -1.0 = Anti-phase (Severe phase cancellation risk)
  static double computeStereoCorrelation(List<double> leftBuffer, List<double> rightBuffer) {
    final int len = math.min(leftBuffer.length, rightBuffer.length);
    if (len == 0) return 1.0;

    double sumLR = 0.0;
    double sumL2 = 0.0;
    double sumR2 = 0.0;

    for (int i = 0; i < len; i++) {
      final double l = leftBuffer[i];
      final double r = rightBuffer[i];
      sumLR += l * r;
      sumL2 += l * l;
      sumR2 += r * r;
    }

    final double denominator = math.sqrt(sumL2 * sumR2);
    if (denominator < 1e-9) return 1.0;

    return (sumLR / denominator).clamp(-1.0, 1.0);
  }

  /// Automatically adjusts stereo width if correlation falls into hazardous anti-phase territory (< 0.1).
  ///
  /// Returns a safe width factor that preserves mono compatibility.
  static double calculateSafeWidth(double requestedWidth, double correlation) {
    if (correlation >= 0.2) {
      return requestedWidth;
    }
    // As correlation dips toward 0.0 and below, gracefully attenuate width
    final double safetyScale = ((correlation + 0.2) / 0.4).clamp(0.3, 1.0);
    return requestedWidth * safetyScale;
  }
}

/// 3D Cartesian Coordinates.
class CartesianCoords {
  final double x; // -1.0 (Left) to +1.0 (Right)
  final double y; // -1.0 (Back) to +1.0 (Front)
  final double z; // -1.0 (Below) to +1.0 (Above)

  const CartesianCoords({required this.x, required this.y, this.z = 0.0});

  @override
  String toString() => 'Cartesian(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, z: ${z.toStringAsFixed(2)})';
}

/// Spherical Coordinates.
class SphericalCoords {
  final double azimuth;   // Radians: 0 = Front, +pi/2 = Right, -pi/2 = Left, pi = Back
  final double distance;  // Normalized distance [0.0, 2.0+]
  final double elevation; // Radians: 0 = Level, +pi/2 = Up, -pi/2 = Down

  const SphericalCoords({
    required this.azimuth,
    required this.distance,
    this.elevation = 0.0,
  });

  /// Azimuth in human-readable degrees (-180° to +180°).
  double get azimuthDegrees => azimuth * 180.0 / math.pi;

  @override
  String toString() => 'Spherical(azimuth: ${azimuthDegrees.toStringAsFixed(1)}°, dist: ${distance.toStringAsFixed(2)})';
}

/// Mid / Side audio representation.
class MidSide {
  final double mid;
  final double side;

  const MidSide({required this.mid, required this.side});
}

/// Stereo L / R gain or sample pair.
class StereoGain {
  final double left;
  final double right;

  const StereoGain({required this.left, required this.right});
}
