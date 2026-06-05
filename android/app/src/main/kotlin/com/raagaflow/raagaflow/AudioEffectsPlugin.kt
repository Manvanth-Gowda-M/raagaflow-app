package com.raagaflow.raagaflow

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.PresetReverb
import android.media.audiofx.Virtualizer
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Timer
import java.util.TimerTask
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

class AudioEffectsPlugin(private val flutterEngine: FlutterEngine) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.raagaflow.audio_effects")

    private var currentSessionId: Int = 0

    // ─── Android Audio Effects ────────────────────────────────────────────────
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var equalizer: Equalizer? = null
    private var presetReverb: PresetReverb? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null

    // ─── Effect State ─────────────────────────────────────────────────────────
    private var is8DEnabled = false
    private var isBassBoostEnabled = false
    private var isSurroundEnabled = false
    private var isVocalBoostEnabled = false
    private var isReverbEnabled = false

    // ─── 8D Audio Rotation State ─────────────────────────────────────────────
    private var timer8D: Timer? = null
    private var angle8D: Double = 0.0
    private var speed8D: Double = 0.012     // radians per tick (20ms) → ~8.4s full rotation
    private var intensity8D: Int = 800       // 0–1000

    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setAudioSessionId" -> {
                val sessionId = call.argument<Int>("sessionId") ?: 0
                if (sessionId != 0 && sessionId != currentSessionId) {
                    releaseEffects()
                    currentSessionId = sessionId
                    initEffects(sessionId)
                    // Re-apply all enabled effects after re-init
                    reapplyEffects()
                }
                result.success(true)
            }

            "setBassBoost" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val intensityParam = call.argument<Int>("intensity") ?: 700
                isBassBoostEnabled = enabled
                applyBassBoost(enabled, intensityParam)
                result.success(true)
            }

            "setVirtualizer" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val intensityParam = call.argument<Int>("intensity") ?: 700
                isSurroundEnabled = enabled
                applySurround(enabled, intensityParam)
                result.success(true)
            }

            "setVocalBoost" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val intensityParam = call.argument<Int>("intensity") ?: 700
                isVocalBoostEnabled = enabled
                applyVocalBoost(enabled, intensityParam)
                result.success(true)
            }

            "setReverb" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                isReverbEnabled = enabled
                applyReverb(enabled)
                result.success(true)
            }

            "set8D" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val intensityParam = call.argument<Int>("intensity") ?: 800
                intensity8D = intensityParam
                is8DEnabled = enabled
                if (enabled) {
                    start8DEffect()
                } else {
                    stop8DEffect()
                }
                result.success(true)
            }

            "release" -> {
                releaseEffects()
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    // ─── Effect Initialization ────────────────────────────────────────────────

    private fun initEffects(sessionId: Int) {
        try { bassBoost = BassBoost(0, sessionId) } catch (e: Exception) { e.printStackTrace() }
        try { virtualizer = Virtualizer(0, sessionId) } catch (e: Exception) { e.printStackTrace() }
        try { equalizer = Equalizer(0, sessionId) } catch (e: Exception) { e.printStackTrace() }
        try { presetReverb = PresetReverb(0, sessionId) } catch (e: Exception) { e.printStackTrace() }
        try { loudnessEnhancer = LoudnessEnhancer(sessionId) } catch (e: Exception) { e.printStackTrace() }
    }

    private fun reapplyEffects() {
        if (isBassBoostEnabled) applyBassBoost(true, 850)
        if (isSurroundEnabled) applySurround(true, 900)
        if (isVocalBoostEnabled) applyVocalBoost(true, 800)
        if (isReverbEnabled) applyReverb(true)
        if (is8DEnabled) start8DEffect()
    }

    private fun releaseEffects() {
        stop8DEffect()
        try { bassBoost?.release() } catch (_: Exception) {}
        try { virtualizer?.release() } catch (_: Exception) {}
        try { equalizer?.release() } catch (_: Exception) {}
        try { presetReverb?.release() } catch (_: Exception) {}
        try { loudnessEnhancer?.release() } catch (_: Exception) {}
        bassBoost = null
        virtualizer = null
        equalizer = null
        presetReverb = null
        loudnessEnhancer = null
    }

    // ─── Bass Boost ───────────────────────────────────────────────────────────
    // Intensity scale: Normal=700, Strong=850, Extreme=1000
    // Also uses LoudnessEnhancer for sub-bass punch.

    private fun applyBassBoost(enabled: Boolean, intensity: Int) {
        try {
            if (enabled) {
                bassBoost?.enabled = true
                if (bassBoost?.strengthSupported == true) {
                    bassBoost?.setStrength(intensity.toShort())
                }
                // Add loudness enhancement for sub-bass body
                val gainMb = when {
                    intensity >= 950 -> 700   // Extreme: +7dB
                    intensity >= 800 -> 500   // Strong: +5dB
                    else             -> 350   // Normal: +3.5dB
                }
                loudnessEnhancer?.enabled = true
                loudnessEnhancer?.setTargetGain(gainMb)
            } else {
                bassBoost?.enabled = false
                // Only disable loudness if 8D is also off (8D uses it for depth)
                if (!is8DEnabled) {
                    loudnessEnhancer?.enabled = false
                }
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    // ─── Surround Sound ───────────────────────────────────────────────────────
    // Virtualizer at maximum strength + high-shelf EQ boost for spatial air.

    private fun applySurround(enabled: Boolean, intensity: Int) {
        try {
            if (enabled) {
                virtualizer?.enabled = true
                if (virtualizer?.strengthSupported == true) {
                    virtualizer?.setStrength(intensity.toShort())
                }
                // When surround is active and EQ is not used for vocal boost, add air
                if (!isVocalBoostEnabled) {
                    setSurroundEQ(true)
                }
            } else {
                virtualizer?.enabled = false
                // Only clear EQ if vocal boost isn't also on
                if (!isVocalBoostEnabled) {
                    clearEQ()
                }
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    private fun setSurroundEQ(enabled: Boolean) {
        try {
            val numBands = equalizer?.numberOfBands?.toInt() ?: 0
            if (numBands >= 5) {
                equalizer?.enabled = true
                equalizer?.setBandLevel(0.toShort(), 0.toShort())
                equalizer?.setBandLevel(1.toShort(), 0.toShort())
                equalizer?.setBandLevel(2.toShort(), 0.toShort())
                equalizer?.setBandLevel(3.toShort(), (200).toShort())  // air
                equalizer?.setBandLevel(4.toShort(), (300).toShort())  // top air
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    // ─── Vocal Boost ──────────────────────────────────────────────────────────
    // Precision 5-band EQ designed around the vocal presence region.
    // Cuts muddiness below 250Hz, boosts presence 1kHz–4kHz.

    private fun applyVocalBoost(enabled: Boolean, intensity: Int) {
        try {
            if (enabled) {
                equalizer?.enabled = true
                val numBands = equalizer?.numberOfBands?.toInt() ?: 0
                if (numBands >= 5) {
                    val scale = intensity / 1000.0
                    // Band 0 (~60Hz): cut mud
                    equalizer?.setBandLevel(0.toShort(), (-600 * scale).toInt().toShort())
                    // Band 1 (~230Hz): cut low-mid mud
                    equalizer?.setBandLevel(1.toShort(), (-400 * scale).toInt().toShort())
                    // Band 2 (~910Hz): presence center — boost hard
                    equalizer?.setBandLevel(2.toShort(), (700 * scale).toInt().toShort())
                    // Band 3 (~3.6kHz): vocal clarity / air — boost strong
                    equalizer?.setBandLevel(3.toShort(), (900 * scale).toInt().toShort())
                    // Band 4 (~14kHz): top-end sibilance enhance
                    equalizer?.setBandLevel(4.toShort(), (400 * scale).toInt().toShort())
                }
            } else {
                if (!isSurroundEnabled) {
                    clearEQ()
                } else {
                    setSurroundEQ(true)
                }
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    private fun clearEQ() {
        try {
            val numBands = equalizer?.numberOfBands?.toInt() ?: 0
            for (i in 0 until numBands) {
                equalizer?.setBandLevel(i.toShort(), 0.toShort())
            }
            equalizer?.enabled = false
        } catch (e: Exception) { e.printStackTrace() }
    }

    // ─── Concert Hall Reverb ──────────────────────────────────────────────────

    private fun applyReverb(enabled: Boolean) {
        try {
            if (enabled) {
                presetReverb?.enabled = true
                presetReverb?.preset = PresetReverb.PRESET_LARGEHALL
            } else {
                presetReverb?.enabled = false
                presetReverb?.preset = PresetReverb.PRESET_NONE
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    // ─── 8D Audio ─────────────────────────────────────────────────────────────
    // True binaural simulation using multiple simultaneous Android effects:
    //   1. Flutter pan callback → just_audio L/R volume differential
    //   2. Virtualizer strength oscillation → front/back depth perception
    //   3. Equalizer high band sweep → distance & Doppler-like sensation
    //   4. LoudnessEnhancer modulation → loudness perspective change

    private fun start8DEffect() {
        stop8DEffect()

        // Make sure 8D effect components are initialized
        try {
            if (!is8DEnabled) return
            // Enable virtualizer for spatial depth
            virtualizer?.enabled = true
            if (virtualizer?.strengthSupported == true) {
                virtualizer?.setStrength(1000.toShort())
            }
            loudnessEnhancer?.enabled = true
        } catch (e: Exception) { e.printStackTrace() }

        timer8D = Timer()
        timer8D?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                if (!is8DEnabled) return

                // Primary rotation angle — SLOW full circle (0.012 rad × 50fps ≈ 8.4 sec/rotation)
                angle8D += speed8D
                if (angle8D > Math.PI * 2) angle8D -= Math.PI * 2

                // ── 1. Main L/R panning signal sent to Flutter ───────────────
                // sin(angle) gives smooth −1.0 to +1.0 oscillation (left → front → right → behind → left)
                val pan = sin(angle8D)

                // ── 2. Front/back depth via Virtualizer strength ─────────────
                // cos peaks when sound is "in front", troughs when "behind".
                // Keep range 700–1000 (never fully off) so it always sounds spatial.
                val depthFactor = (cos(angle8D) * 0.5 + 0.5)  // 0.0–1.0
                val virtualizerStrength = (700 + (depthFactor * 300)).toInt()  // 700–1000
                try {
                    if (virtualizer?.strengthSupported == true) {
                        virtualizer?.setStrength(virtualizerStrength.toShort())
                    }
                } catch (_: Exception) {}

                // ── 3. EQ Doppler frequency sweep (THE KEY to 8D feel) ────────
                // As sound rotates past your ear, high frequencies appear to shift.
                // Sweep band 3 (3.6kHz) and band 4 (14kHz) with opposing curves:
                // When sound is to the LEFT  → band 3 boosted, band 4 dipped
                // When sound is to the RIGHT → band 3 dipped,  band 4 boosted
                // This creates the "sweeping past the ear" Doppler illusion.
                val eqSweepHigh = (sin(angle8D) * 600).toInt()       // ±600 mb at 14kHz
                val eqSweepMid  = (sin(angle8D + Math.PI) * 350).toInt()  // opposing curve at 3.6kHz
                try {
                    val numBands = equalizer?.numberOfBands?.toInt() ?: 0
                    if (numBands >= 5 && !isVocalBoostEnabled) {
                        equalizer?.enabled = true
                        equalizer?.setBandLevel(0.toShort(), 0.toShort())
                        equalizer?.setBandLevel(1.toShort(), 0.toShort())
                        equalizer?.setBandLevel(2.toShort(), 0.toShort())
                        equalizer?.setBandLevel(3.toShort(), eqSweepMid.toShort())
                        equalizer?.setBandLevel(4.toShort(), eqSweepHigh.toShort())
                    }
                } catch (_: Exception) {}

                // ── 4. SUBTLE loudness depth ─────────────────────────────────
                // VERY small volume change — the effect should come from FREQUENCY,
                // not volume pumping. Max 80mb = barely perceptible loudness shift.
                val loudnessDelta = (depthFactor * 80).toInt()   // 0–80 mb only
                try {
                    loudnessEnhancer?.setTargetGain(loudnessDelta)
                } catch (_: Exception) {}

                // ── 5. Send pan to Flutter ───────────────────────────────────
                mainHandler.post {
                    channel.invokeMethod("on8DPanUpdate", mapOf("pan" to pan, "depth" to depthFactor))
                }
            }
        }, 0, 20)  // 20ms ticks = 50fps smooth animation
    }

    private fun stop8DEffect() {
        timer8D?.cancel()
        timer8D = null
        angle8D = 0.0

        // Restore virtualizer to neutral if surround is also off
        try {
            if (!isSurroundEnabled) {
                virtualizer?.enabled = false
            }
            loudnessEnhancer?.enabled = false
            // Reset EQ high bands
            if (!isVocalBoostEnabled) {
                clearEQ()
            }
        } catch (_: Exception) {}

        mainHandler.post {
            channel.invokeMethod("on8DPanUpdate", mapOf("pan" to 0.0, "depth" to 0.5))
        }
    }
}
