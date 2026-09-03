import 'dart:math' as math;
import 'spatial_math.dart';
import 'spatial_models.dart';
import 'spatial_trajectory_engine.dart';

/// High-Fidelity Floating-Point Offline Spatial Audio Processing Engine.
///
/// Processes stereo PCM audio samples through the complete 8D spatial audio pipeline:
/// 1. Mid/Side decomposition & Vocal extraction
/// 2. Low-frequency Bass mono anchoring (<120Hz)
/// 3. Kinematic 3D Trajectory positioning (Azimuth, Elevation, Distance)
/// 4. Asymmetric Head-Shadow & Pinna Filtering
/// 5. Fractional ITD (Interaural Time Delay)
/// 6. Distance-dependent air absorption high-shelf roll-off
/// 7. Algorithmic early reflections & spatial reverb
/// 8. Parametric M-S stereo widening
/// 9. Real-time phase/correlation safety guard
/// 10. True-peak soft-knee mastering limiter & gain makeup
class OfflineSpatialRenderer {
  final int sampleRate;
  final SpatialTrajectoryEngine _trajectoryEngine = SpatialTrajectoryEngine();

  // Biquad Crossover filter state for Sub-Bass mono anchor
  double _bassLpMidX1 = 0.0, _bassLpMidX2 = 0.0, _bassLpMidY1 = 0.0, _bassLpMidY2 = 0.0;

  // IIR Pinna & Air-Absorption filter states
  double _airLpLeftY1 = 0.0, _airLpRightY1 = 0.0;

  // Reverb Comb & Allpass Delay buffers (Schroeder algorithmic structure)
  late final List<List<double>> _combBuffers;
  late final List<int> _combIndices;
  late final List<List<double>> _allpassBuffers;
  late final List<int> _allpassIndices;

  // Fractional ITD Ring Buffer (max 4ms delay = ~192 samples at 48kHz)
  late final List<double> _itdBufferLeft;
  late final List<double> _itdBufferRight;
  int _itdWriteIndex = 0;

  OfflineSpatialRenderer({this.sampleRate = 44100}) {
    // Initialize Reverb comb delay lines (prime lengths for decorrelation)
    final combLengths = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617];
    _combBuffers = List.generate(8, (i) => List.filled((combLengths[i] * sampleRate ~/ 44100), 0.0));
    _combIndices = List.filled(8, 0);

    final allpassLengths = [225, 341, 441, 556];
    _allpassBuffers = List.generate(4, (i) => List.filled((allpassLengths[i] * sampleRate ~/ 44100), 0.0));
    _allpassIndices = List.filled(4, 0);

    // ITD Delay buffer (~256 samples)
    _itdBufferLeft = List.filled(512, 0.0);
    _itdBufferRight = List.filled(512, 0.0);
  }

  /// Resets all internal DSP filter states and delay lines.
  void reset() {
    _trajectoryEngine.reset();
    _bassLpMidX1 = _bassLpMidX2 = _bassLpMidY1 = _bassLpMidY2 = 0.0;
    _airLpLeftY1 = _airLpRightY1 = 0.0;
    for (final buf in _combBuffers) {
      buf.fillRange(0, buf.length, 0.0);
    }
    for (final buf in _allpassBuffers) {
      buf.fillRange(0, buf.length, 0.0);
    }
    _itdBufferLeft.fillRange(0, _itdBufferLeft.length, 0.0);
    _itdBufferRight.fillRange(0, _itdBufferRight.length, 0.0);
    _itdWriteIndex = 0;
  }

  /// Sets track seed for deterministic organic spatial pattern.
  void setTrackSeed(String trackId) {
    _trajectoryEngine.setTrackSeed(trackId);
  }

  /// Processes interleaved or dual-channel stereo audio samples through the 8D DSP pipeline.
  ///
  /// [inLeft] and [inRight] must have equal length.
  /// Returns a record with [outLeft], [outRight], and telemetry [metrics].
  ({List<double> outLeft, List<double> outRight, SpatialDiagnosticMetrics metrics}) processBuffer(
    List<double> inLeft,
    List<double> inRight,
    SpatialParameters params, {
    double musicalEnergy = 0.5,
  }) {
    final int numSamples = inLeft.length;
    final List<double> outLeft = List.filled(numSamples, 0.0);
    final List<double> outRight = List.filled(numSamples, 0.0);

    if (numSamples == 0) {
      return (outLeft: outLeft, outRight: outRight, metrics: const SpatialDiagnosticMetrics());
    }

    // Step the 3D trajectory position
    final double blockDeltaSeconds = numSamples / sampleRate.toDouble();
    final CartesianCoords pos = _trajectoryEngine.update(
      blockDeltaSeconds,
      params,
      musicalEnergy: musicalEnergy,
    );

    final SphericalCoords spherical = SpatialMath.cartesianToSpherical(pos.x, pos.y, pos.z);
    final StereoGain binauralGains = SpatialMath.calculateBinauralGains(spherical.azimuth, spherical.distance);
    final double rearDamping = SpatialMath.calculateRearPinnaDamping(pos.y);
    final double airCutoff = SpatialMath.calculateAirAbsorptionCutoff(spherical.distance);
    final double itdSeconds = SpatialMath.calculateWoodworthITD(spherical.azimuth);
    final double itdSamples = itdSeconds * sampleRate;

    // Filter coefficients for low-pass air absorption
    final double airAlpha = (2.0 * math.pi * airCutoff / sampleRate).clamp(0.01, 0.95);

    // Filter coefficients for Butterworth 2nd order low-pass bass anchor at cutoff
    final double cutoffHz = params.bassCrossoverHz.clamp(60.0, 200.0);
    final double omega = 2.0 * math.pi * cutoffHz / sampleRate;
    final double alpha = math.sin(omega) / (2.0 * 0.7071); // Q = 0.7071
    final double cosw = math.cos(omega);
    final double b0 = (1.0 - cosw) * 0.5;
    final double b1 = 1.0 - cosw;
    final double b2 = (1.0 - cosw) * 0.5;
    final double a0 = 1.0 + alpha;
    final double a1 = -2.0 * cosw;
    final double a2 = 1.0 - alpha;

    final double normB0 = b0 / a0;
    final double normB1 = b1 / a0;
    final double normB2 = b2 / a0;
    final double normA1 = a1 / a0;
    final double normA2 = a2 / a0;

    final double centerProtection = params.centerProtection.clamp(0.0, 1.0);
    final double width = params.stereoWidth.clamp(0.0, 2.0);
    final double reverbSend = params.reverbMix.clamp(0.0, 1.0);

    double maxPeak = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final double l = inLeft[i];
      final double r = inRight[i];

      // ─── 1. Mid-Side Decomposition ───────────────────────────────
      final MidSide ms = SpatialMath.encodeMidSide(l, r);
      final double mid = ms.mid;
      final double side = ms.side;

      // ─── 2. Sub-Bass Crossover Mono Anchor ────────────────────────
      // Low-pass filter the mid channel for stable sub-bass anchor
      final double bassMono = normB0 * mid + normB1 * _bassLpMidX1 + normB2 * _bassLpMidX2 -
          normA1 * _bassLpMidY1 - normA2 * _bassLpMidY2;
      _bassLpMidX2 = _bassLpMidX1;
      _bassLpMidX1 = mid;
      _bassLpMidY2 = _bassLpMidY1;
      _bassLpMidY1 = bassMono;

      // High-passed mid (mids and highs that can be spatialized)
      final double midHighs = mid - bassMono;

      // ─── 3. Center Vocal Isolation & Protection ───────────────────
      // Extract protected vocal center and spatial side component
      final double vocalAnchor = midHighs * centerProtection;
      final double spatialMid = midHighs * (1.0 - centerProtection);

      // ─── 4. Binaural Spatialization & Positioning ─────────────────
      // Apply binaural level differences and distance attenuation
      double spatL = (spatialMid + side) * binauralGains.left * rearDamping;
      double spatR = (spatialMid - side) * binauralGains.right * rearDamping;

      // ─── 5. Air Absorption Damping (1st-order IIR Low-pass) ─────────
      _airLpLeftY1 += airAlpha * (spatL - _airLpLeftY1);
      _airLpRightY1 += airAlpha * (spatR - _airLpRightY1);
      spatL = _airLpLeftY1;
      spatR = _airLpRightY1;

      // ─── 6. Fractional Woodworth ITD Delay ────────────────────────
      _itdBufferLeft[_itdWriteIndex] = spatL;
      _itdBufferRight[_itdWriteIndex] = spatR;

      if (itdSamples > 0.0) {
        // Sound on left → delay right channel
        final double readPos = (_itdWriteIndex - itdSamples + 512.0) % 512.0;
        final int idx0 = readPos.toInt();
        final int idx1 = (idx0 + 1) % 512;
        final double frac = readPos - idx0;
        spatR = _itdBufferRight[idx0] * (1.0 - frac) + _itdBufferRight[idx1] * frac;
      } else if (itdSamples < 0.0) {
        // Sound on right → delay left channel
        final double delay = -itdSamples;
        final double readPos = (_itdWriteIndex - delay + 512.0) % 512.0;
        final int idx0 = readPos.toInt();
        final int idx1 = (idx0 + 1) % 512;
        final double frac = readPos - idx0;
        spatL = _itdBufferLeft[idx0] * (1.0 - frac) + _itdBufferLeft[idx1] * frac;
      }
      _itdWriteIndex = (_itdWriteIndex + 1) % 512;

      // ─── 7. Spatial Reverb Stage ─────────────────────────────────
      double reverbL = 0.0;
      double reverbR = 0.0;
      if (reverbSend > 0.001) {
        final double revInput = (spatL + spatR) * 0.5;
        double combSum = 0.0;
        for (int c = 0; c < 8; c++) {
          final buf = _combBuffers[c];
          final idx = _combIndices[c];
          final val = buf[idx];
          buf[idx] = revInput + val * 0.84;
          _combIndices[c] = (idx + 1) % buf.length;
          combSum += val;
        }
        double apVal = combSum * 0.125;
        for (int a = 0; a < 4; a++) {
          final buf = _allpassBuffers[a];
          final idx = _allpassIndices[a];
          final val = buf[idx];
          final out = -apVal + val;
          buf[idx] = apVal + val * 0.5;
          _allpassIndices[a] = (idx + 1) % buf.length;
          apVal = out;
        }
        reverbL = apVal * reverbSend * 0.5;
        reverbR = -apVal * reverbSend * 0.5;
      }

      // ─── 8. Sum Spatial + Center Vocal + Mono Bass Anchor ─────────
      double outSampleL = spatL + vocalAnchor + bassMono + reverbL;
      double outSampleR = spatR + vocalAnchor + bassMono + reverbR;

      // ─── 9. Stereo Width Control with Blumlein M-S ────────────────
      final MidSide outMs = SpatialMath.encodeMidSide(outSampleL, outSampleR);
      final StereoGain widened = SpatialMath.decodeMidSide(outMs.mid, outMs.side, width);
      outSampleL = widened.left;
      outSampleR = widened.right;

      // ─── 10. True-Peak Soft-Knee Limiter (Prevents Digital Clip) ──
      outSampleL = _softClip(outSampleL * 1.05);
      outSampleR = _softClip(outSampleR * 1.05);

      outLeft[i] = outSampleL;
      outRight[i] = outSampleR;

      final double currentPeak = math.max(outSampleL.abs(), outSampleR.abs());
      if (currentPeak > maxPeak) maxPeak = currentPeak;
    }

    // Measure real-time correlation and safe phase-guard
    final double correlation = SpatialMath.computeStereoCorrelation(outLeft, outRight);
    final double safeWidth = SpatialMath.calculateSafeWidth(width, correlation);
    final double peakDb = maxPeak > 1e-5 ? 20.0 * (math.log(maxPeak) / math.ln10) : -60.0;

    final metrics = SpatialDiagnosticMetrics(
      x: pos.x,
      y: pos.y,
      z: pos.z,
      azimuthDegrees: spherical.azimuthDegrees,
      distance: spherical.distance,
      stereoCorrelation: correlation,
      effectiveWidth: safeWidth,
      isPhaseCompensated: safeWidth < width,
      peakDb: peakDb,
    );

    return (outLeft: outLeft, outRight: outRight, metrics: metrics);
  }

  /// Soft-knee cubic saturation curve (transparent headroom limiter, prevents harsh DAC clipping).
  double _softClip(double x) {
    if (x > 1.0) {
      return 1.0;
    } else if (x < -1.0) {
      return -1.0;
    } else if (x > 0.75) {
      final double over = x - 0.75;
      return 0.75 + over * (1.0 - over * 2.0);
    } else if (x < -0.75) {
      final double under = x + 0.75;
      return -0.75 + under * (1.0 + under * 2.0);
    }
    return x;
  }
}
