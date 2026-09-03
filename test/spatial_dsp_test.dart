import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:raagaflow/core/audio_dsp/spatial_math.dart';
import 'package:raagaflow/core/audio_dsp/spatial_models.dart';
import 'package:raagaflow/core/audio_dsp/spatial_trajectory_engine.dart';
import 'package:raagaflow/core/audio_dsp/offline_spatial_renderer.dart';

void main() {
  group('SpatialMath Tests', () {
    test('Cartesian to Spherical conversion accuracy', () {
      // Front (0, 1) -> Azimuth 0 rad, distance 1.0
      final front = SpatialMath.cartesianToSpherical(0.0, 1.0);
      expect(front.azimuthDegrees, closeTo(0.0, 0.01));
      expect(front.distance, closeTo(1.0, 0.01));

      // Right (1, 0) -> Azimuth +90 deg, distance 1.0
      final right = SpatialMath.cartesianToSpherical(1.0, 0.0);
      expect(right.azimuthDegrees, closeTo(90.0, 0.01));
      expect(right.distance, closeTo(1.0, 0.01));

      // Left (-1, 0) -> Azimuth -90 deg, distance 1.0
      final left = SpatialMath.cartesianToSpherical(-1.0, 0.0);
      expect(left.azimuthDegrees, closeTo(-90.0, 0.01));
      expect(left.distance, closeTo(1.0, 0.01));

      // Back (0, -1) -> Azimuth 180 deg, distance 1.0
      final back = SpatialMath.cartesianToSpherical(0.0, -1.0);
      expect(back.azimuthDegrees.abs(), closeTo(180.0, 0.01));
      expect(back.distance, closeTo(1.0, 0.01));
    });

    test('Round-trip Cartesian <-> Spherical conversion preserves coordinates', () {
      const double origX = 0.65;
      const double origY = -0.45;
      const double origZ = 0.20;

      final spherical = SpatialMath.cartesianToSpherical(origX, origY, origZ);
      final cartesian = SpatialMath.sphericalToCartesian(spherical.azimuth, spherical.distance, spherical.elevation);

      expect(cartesian.x, closeTo(origX, 1e-4));
      expect(cartesian.y, closeTo(origY, 1e-4));
      expect(cartesian.z, closeTo(origZ, 1e-4));
    });

    test('Woodworth ITD is strictly bounded by human acoustic limit (~650us)', () {
      // At center (0 deg) -> ITD should be 0.0
      final centerItd = SpatialMath.calculateWoodworthITD(0.0);
      expect(centerItd, closeTo(0.0, 1e-6));

      // At 90 deg (pi/2) -> ITD should not exceed ~650 microseconds
      final itd90 = SpatialMath.calculateWoodworthITD(math.pi / 2.0);
      expect(itd90.abs(), lessThanOrEqualTo(SpatialMath.maxItdSeconds));
      expect(itd90.abs(), greaterThan(0.0004)); // >400us

      // Symmetric for left and right
      final itdMinus90 = SpatialMath.calculateWoodworthITD(-math.pi / 2.0);
      expect(itd90, closeTo(-itdMinus90, 1e-6));
    });

    test('Mid-Side encoding and decoding is lossless identity at width = 1.0', () {
      const double origL = 0.723;
      const double origR = -0.418;

      final ms = SpatialMath.encodeMidSide(origL, origR);
      final reconstructed = SpatialMath.decodeMidSide(ms.mid, ms.side, 1.0);

      expect(reconstructed.left, closeTo(origL, 1e-6));
      expect(reconstructed.right, closeTo(origR, 1e-6));
    });

    test('Mid-Side at width = 0.0 collapses to pure mono (L == R == Mid)', () {
      const double origL = 0.8;
      const double origR = -0.2;

      final ms = SpatialMath.encodeMidSide(origL, origR);
      final mono = SpatialMath.decodeMidSide(ms.mid, ms.side, 0.0);

      expect(mono.left, closeTo(mono.right, 1e-6));
      expect(mono.left, closeTo((origL + origR) / 2.0, 1e-6));
    });

    test('Air absorption cutoff frequency decreases smoothly with distance', () {
      final nearCutoff = SpatialMath.calculateAirAbsorptionCutoff(0.0);
      final midCutoff = SpatialMath.calculateAirAbsorptionCutoff(1.0);
      final farCutoff = SpatialMath.calculateAirAbsorptionCutoff(2.0);

      expect(nearCutoff, closeTo(20000.0, 1.0));
      expect(midCutoff, lessThan(nearCutoff));
      expect(farCutoff, lessThan(midCutoff));
      expect(farCutoff, greaterThan(8000.0));
    });

    test('Pearson stereo correlation accurately identifies phase alignment', () {
      // Identical signals in-phase -> correlation = +1.0
      final inPhaseL = [0.1, 0.5, 0.9, 0.3, -0.4, -0.8];
      final inPhaseR = [0.1, 0.5, 0.9, 0.3, -0.4, -0.8];
      final rhoInPhase = SpatialMath.computeStereoCorrelation(inPhaseL, inPhaseR);
      expect(rhoInPhase, closeTo(1.0, 1e-4));

      // Anti-phase signals -> correlation = -1.0
      final antiPhaseR = inPhaseL.map((x) => -x).toList();
      final rhoAntiPhase = SpatialMath.computeStereoCorrelation(inPhaseL, antiPhaseR);
      expect(rhoAntiPhase, closeTo(-1.0, 1e-4));

      // Orthogonal signals -> correlation ~ 0.0
      final orthoL = [1.0, 0.0, -1.0, 0.0];
      final orthoR = [0.0, 1.0, 0.0, -1.0];
      final rhoOrtho = SpatialMath.computeStereoCorrelation(orthoL, orthoR);
      expect(rhoOrtho, closeTo(0.0, 1e-4));
    });

    test('Phase safety limiter automatically attenuates width on hazardous correlation', () {
      const double requestedWidth = 1.8;

      // Safe correlation (0.8) -> width unchanged
      final safe1 = SpatialMath.calculateSafeWidth(requestedWidth, 0.8);
      expect(safe1, closeTo(requestedWidth, 1e-4));

      // Hazardous negative correlation (-0.2) -> width significantly reduced to preserve mono
      final safe2 = SpatialMath.calculateSafeWidth(requestedWidth, -0.2);
      expect(safe2, lessThan(requestedWidth));
      expect(safe2, greaterThan(0.0));
    });
  });

  group('SpatialTrajectoryEngine Tests', () {
    late SpatialTrajectoryEngine engine;

    setUp(() {
      engine = SpatialTrajectoryEngine();
    });

    test('All trajectory types generate valid bounded coordinates', () {
      final presets = [
        TrajectoryType.orbit,
        TrajectoryType.figureEight,
        TrajectoryType.dreamSpace,
        TrajectoryType.cinematic,
        TrajectoryType.manual,
      ];

      for (final traj in presets) {
        engine.reset();
        final params = SpatialParameters(
          trajectory: traj,
          intensity: 1.0,
          orbitRadius: 1.0,
          speedRadPerSec: 1.0,
        );

        for (int step = 0; step < 100; step++) {
          final pos = engine.update(0.05, params);
          expect(pos.x.isNaN, isFalse, reason: 'x is NaN for $traj');
          expect(pos.y.isNaN, isFalse, reason: 'y is NaN for $traj');
          expect(pos.z.isNaN, isFalse, reason: 'z is NaN for $traj');
          expect(pos.x.isInfinite, isFalse);
          expect(pos.y.isInfinite, isFalse);
          expect(pos.z.isInfinite, isFalse);
          expect(pos.x.abs(), lessThanOrEqualTo(2.0));
          expect(pos.y.abs(), lessThanOrEqualTo(2.0));
        }
      }
    });

    test('Deterministic track seed produces repeatable organic motion', () {
      final engine1 = SpatialTrajectoryEngine()..setTrackSeed('track_hindi_romantic_491');
      final engine2 = SpatialTrajectoryEngine()..setTrackSeed('track_hindi_romantic_491');
      const params = SpatialParameters(trajectory: TrajectoryType.orbit);

      for (int i = 0; i < 20; i++) {
        final pos1 = engine1.update(0.02, params);
        final pos2 = engine2.update(0.02, params);
        expect(pos1.x, closeTo(pos2.x, 1e-5));
        expect(pos1.y, closeTo(pos2.y, 1e-5));
      }
    });
  });

  group('Spatial Preset Validation', () {
    test('All 10 Flagship Presets have safe DSP parameter invariants', () {
      for (final preset in SpatialPresetType.values) {
        final p = preset.defaultParameters;
        expect(p.intensity, inInclusiveRange(0.0, 1.0), reason: '${preset.name} intensity out of range');
        expect(p.stereoWidth, inInclusiveRange(0.5, 2.0), reason: '${preset.name} width out of range');
        expect(p.centerProtection, inInclusiveRange(0.0, 1.0), reason: '${preset.name} vocal protection out of range');
        expect(p.bassCrossoverHz, inInclusiveRange(60.0, 200.0), reason: '${preset.name} bass crossover out of range');
        expect(p.reverbMix, inInclusiveRange(0.0, 1.0), reason: '${preset.name} reverb mix out of range');
        expect(p.delayMix, inInclusiveRange(0.0, 1.0), reason: '${preset.name} delay mix out of range');
      }
    });
  });

  group('OfflineSpatialRenderer Buffer Processing Tests', () {
    late OfflineSpatialRenderer renderer;

    setUp(() {
      renderer = OfflineSpatialRenderer(sampleRate: 44100);
    });

    test('Full DSP pipeline processes audio without clipping, NaNs, or crashes', () {
      // Generate 1 second of stereo test audio (440Hz tone left, 880Hz tone right)
      const int sampleCount = 44100;
      final inLeft = List.generate(sampleCount, (i) => 0.5 * math.sin(2 * math.pi * 440 * i / 44100));
      final inRight = List.generate(sampleCount, (i) => 0.5 * math.sin(2 * math.pi * 880 * i / 44100));

      final result = renderer.processBuffer(
        inLeft,
        inRight,
        SpatialPresetType.deep8D.defaultParameters,
      );

      expect(result.outLeft.length, equals(sampleCount));
      expect(result.outRight.length, equals(sampleCount));

      for (int i = 0; i < sampleCount; i++) {
        final l = result.outLeft[i];
        final r = result.outRight[i];
        expect(l.isNaN, isFalse);
        expect(r.isNaN, isFalse);
        expect(l.isInfinite, isFalse);
        expect(r.isInfinite, isFalse);
        // Soft-knee limiter guarantees samples stay within [-1.0, 1.0]
        expect(l.abs(), lessThanOrEqualTo(1.0001));
        expect(r.abs(), lessThanOrEqualTo(1.0001));
      }

      // Telemetry metrics check
      expect(result.metrics.distance, greaterThan(0.0));
      expect(result.metrics.stereoCorrelation, inInclusiveRange(-1.0, 1.0));
    });
  });
}
