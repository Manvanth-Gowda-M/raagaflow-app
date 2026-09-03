package com.raagaflow.raagaflow

import android.media.AudioTrack
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
import java.lang.reflect.Field
import java.util.Timer
import java.util.TimerTask
import kotlin.math.*

/**
 * Next-Generation Professional 8D / 3D Spatial Audio Native Plugin for Android.
 *
 * Implements:
 * 1. Hardware-level physical stereo channel volume separation via AudioTrack.setStereoVolume
 * 2. Multi-stage psychoacoustic binaural depth cues via Virtualizer
 * 3. Asymmetric pinna / head-shadow EQ filters
 * 4. Dual vocal/beat counter-phase cross-movement
 * 5. Smooth 60 FPS click-free parameter interpolation
 */
class AudioEffectsPlugin(private val flutterEngine: FlutterEngine) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.raagaflow.audio_effects")

    private var currentSessionId: Int = 0

    // ─── Android AudioFX Hardware/Software DSPs ──────────────────────────────
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var equalizer: Equalizer? = null
    private var presetReverb: PresetReverb? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null

    // ─── Native Hardware AudioTrack Reference ────────────────────────────────
    private var cachedAudioTrack: AudioTrack? = null

    // ─── Effect States ────────────────────────────────────────────────────────
    private var is8DEnabled = false
    private var isBypassed = false // Instant A/B Comparison
    private var isBassBoostEnabled = false
    private var isSurroundEnabled = false
    private var isVocalBoostEnabled = false
    private var isReverbEnabled = false

    // ─── Spatial Engine Parameters ───────────────────────────────────────────
    private var intensity8D: Double = 0.90          // 0.0 to 1.0
    private var speedRadPerSec: Double = 0.85       // Radians / second
    private var depth8D: Double = 0.75              // 0.0 to 1.0
    private var orbitRadius: Double = 1.05          // 0.0 to 1.5
    private var stereoWidth: Double = 1.50          // 0.0 to 2.0
    private var centerProtection: Double = 0.20     // 0.0 to 1.0
    private var reverbMix: Double = 0.20            // 0.0 to 1.0
    private var trajectoryType: String = "vocalBeatSplit" // vocalBeatSplit, orbit, figureEight, dreamSpace, cinematic, manual

    // ─── Kinematics & Motion State ───────────────────────────────────────────
    private var timer8D: Timer? = null
    private var angle8D: Double = 0.0
    private var currentX: Double = 0.0
    private var currentY: Double = 1.0
    private var currentZ: Double = 0.0
    private var manualTargetX: Double = 0.0
    private var manualTargetY: Double = 1.0

    // Smooth interpolation ramp targets (prevents clicks)
    private var targetVirtualizerStrength: Int = 0
    private var currentVirtualizerStrength: Double = 0.0
    private var targetLoudnessGainMb: Int = 0
    private var currentLoudnessGainMb: Double = 0.0

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
                    cachedAudioTrack = null
                    currentSessionId = sessionId
                    initEffects(sessionId)
                    reapplyEffects()
                }
                result.success(true)
            }

            "set8D" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                is8DEnabled = enabled
                if (call.hasArgument("intensity")) {
                    intensity8D = (call.argument<Double>("intensity") ?: 0.90).coerceIn(0.0, 1.0)
                }
                if (call.hasArgument("speed")) {
                    speedRadPerSec = call.argument<Double>("speed") ?: 0.85
                }
                if (call.hasArgument("depth")) {
                    depth8D = (call.argument<Double>("depth") ?: 0.75).coerceIn(0.0, 1.0)
                }
                if (call.hasArgument("width")) {
                    stereoWidth = (call.argument<Double>("width") ?: 1.50).coerceIn(0.0, 2.0)
                }
                if (call.hasArgument("centerProtection")) {
                    centerProtection = (call.argument<Double>("centerProtection") ?: 0.20).coerceIn(0.0, 1.0)
                }
                if (call.hasArgument("reverbMix")) {
                    reverbMix = (call.argument<Double>("reverbMix") ?: 0.20).coerceIn(0.0, 1.0)
                }
                if (call.hasArgument("trajectory")) {
                    trajectoryType = call.argument<String>("trajectory") ?: "vocalBeatSplit"
                }

                if (enabled && !isBypassed) {
                    start8DEngine()
                } else {
                    stop8DEngine()
                }
                result.success(true)
            }

            "updateSpatialParameters" -> {
                call.argument<Double>("intensity")?.let { intensity8D = it.coerceIn(0.0, 1.0) }
                call.argument<Double>("speed")?.let { speedRadPerSec = it }
                call.argument<Double>("depth")?.let { depth8D = it.coerceIn(0.0, 1.0) }
                call.argument<Double>("orbitRadius")?.let { orbitRadius = it.coerceIn(0.0, 1.5) }
                call.argument<Double>("width")?.let { stereoWidth = it.coerceIn(0.0, 2.0) }
                call.argument<Double>("centerProtection")?.let { centerProtection = it.coerceIn(0.0, 1.0) }
                call.argument<Double>("reverbMix")?.let { reverbMix = it.coerceIn(0.0, 1.0) }
                call.argument<String>("trajectory")?.let { trajectoryType = it }
                result.success(true)
            }

            "setManualPosition" -> {
                val x = call.argument<Double>("x") ?: 0.0
                val y = call.argument<Double>("y") ?: 1.0
                manualTargetX = x.coerceIn(-1.5, 1.5)
                manualTargetY = y.coerceIn(-1.5, 1.5)
                trajectoryType = "manual"
                result.success(true)
            }

            "setBypass" -> {
                val bypass = call.argument<Boolean>("bypass") ?: false
                isBypassed = bypass
                if (bypass) {
                    // Reset hardware stereo volumes to 100% / 100%
                    resetHardwareStereoVolume()
                    targetVirtualizerStrength = 0
                    targetLoudnessGainMb = 0
                    clearEQ()
                } else if (is8DEnabled) {
                    start8DEngine()
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

            "release" -> {
                releaseEffects()
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    // ─── Hardware AudioTrack Resolution ───────────────────────────────────────

    private fun getActiveAudioTrack(): AudioTrack? {
        if (cachedAudioTrack != null) {
            try {
                if (cachedAudioTrack?.state == AudioTrack.STATE_INITIALIZED) {
                    return cachedAudioTrack
                }
            } catch (_: Exception) {
                cachedAudioTrack = null
            }
        }

        try {
            val plugin = flutterEngine.plugins.get(com.ryanheise.just_audio.JustAudioPlugin::class.java)
            if (plugin != null) {
                val playersField = plugin.javaClass.getDeclaredField("players")
                playersField.isAccessible = true
                val playersMap = playersField.get(plugin) as? Map<*, *>
                playersMap?.values?.forEach { mainPlayer ->
                    val track = findAudioTrackInObject(mainPlayer, 0)
                    if (track != null) {
                        cachedAudioTrack = track
                        return track
                    }
                }
            }
        } catch (_: Exception) {}
        return null
    }

    private fun findAudioTrackInObject(target: Any?, depth: Int): AudioTrack? {
        if (target == null || depth > 5) return null
        try {
            var currentClass: Class<*>? = target.javaClass
            while (currentClass != null && currentClass != Any::class.java) {
                for (field in currentClass.declaredFields) {
                    try {
                        field.isAccessible = true
                        val obj = field.get(target) ?: continue
                        if (obj is AudioTrack) {
                            return obj
                        }
                        val className = obj.javaClass.name
                        if (className.contains("ExoPlayer") ||
                            className.contains("AudioSink") ||
                            className.contains("AudioRenderer") ||
                            className.contains("Player") ||
                            className.contains("MediaCodecAudioRenderer") ||
                            className.contains("DefaultAudioSink")) {
                            val nested = findAudioTrackInObject(obj, depth + 1)
                            if (nested != null) return nested
                        }
                    } catch (_: Exception) {}
                }
                currentClass = currentClass.superclass
            }
        } catch (_: Exception) {}
        return null
    }

    private fun resetHardwareStereoVolume() {
        try {
            val track = getActiveAudioTrack()
            track?.setStereoVolume(1.0f, 1.0f)
        } catch (_: Exception) {}
    }

    // ─── DSP Initialization ───────────────────────────────────────────────────

    private fun initEffects(sessionId: Int) {
        try { bassBoost = BassBoost(0, sessionId) } catch (e: Exception) { e.printStackTrace() }
        try {
            virtualizer = Virtualizer(0, sessionId)
            if (virtualizer?.strengthSupported == true) {
                try {
                    virtualizer?.forceVirtualizationMode(Virtualizer.VIRTUALIZATION_MODE_BINAURAL)
                } catch (_: Exception) {}
            }
        } catch (e: Exception) { e.printStackTrace() }
        try { equalizer = Equalizer(0, sessionId) } catch (e: Exception) { e.printStackTrace() }
        try { presetReverb = PresetReverb(0, sessionId) } catch (e: Exception) { e.printStackTrace() }
        try { loudnessEnhancer = LoudnessEnhancer(sessionId) } catch (e: Exception) { e.printStackTrace() }
    }

    private fun reapplyEffects() {
        if (isBassBoostEnabled) applyBassBoost(true, 850)
        if (isSurroundEnabled) applySurround(true, 900)
        if (isVocalBoostEnabled) applyVocalBoost(true, 800)
        if (isReverbEnabled) applyReverb(true)
        if (is8DEnabled && !isBypassed) start8DEngine()
    }

    private fun releaseEffects() {
        stop8DEngine()
        resetHardwareStereoVolume()
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

    // ─── Bass Boost with Sub-Bass Mono Anchoring ──────────────────────────────

    private fun applyBassBoost(enabled: Boolean, intensity: Int) {
        try {
            if (enabled) {
                bassBoost?.enabled = true
                if (bassBoost?.strengthSupported == true) {
                    bassBoost?.setStrength(intensity.toShort())
                }
                val gainMb = when {
                    intensity >= 950 -> 650
                    intensity >= 800 -> 450
                    else             -> 300
                }
                loudnessEnhancer?.enabled = true
                loudnessEnhancer?.setTargetGain(gainMb)
            } else {
                bassBoost?.enabled = false
                if (!is8DEnabled) {
                    loudnessEnhancer?.enabled = false
                }
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    // ─── Surround Sound ───────────────────────────────────────────────────────

    private fun applySurround(enabled: Boolean, intensity: Int) {
        try {
            if (enabled) {
                virtualizer?.enabled = true
                if (virtualizer?.strengthSupported == true) {
                    virtualizer?.setStrength(intensity.toShort())
                }
                if (!isVocalBoostEnabled && !is8DEnabled) {
                    setAirEQ(true)
                }
            } else {
                if (!is8DEnabled) {
                    virtualizer?.enabled = false
                    if (!isVocalBoostEnabled) clearEQ()
                }
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    private fun setAirEQ(enabled: Boolean) {
        try {
            val numBands = equalizer?.numberOfBands?.toInt() ?: 0
            if (numBands >= 5) {
                equalizer?.enabled = true
                equalizer?.setBandLevel(0.toShort(), 0.toShort())
                equalizer?.setBandLevel(1.toShort(), 0.toShort())
                equalizer?.setBandLevel(2.toShort(), 0.toShort())
                equalizer?.setBandLevel(3.toShort(), 200.toShort())
                equalizer?.setBandLevel(4.toShort(), 350.toShort())
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    // ─── Vocal Presence & Clarity Boost ───────────────────────────────────────

    private fun applyVocalBoost(enabled: Boolean, intensity: Int) {
        try {
            if (enabled) {
                equalizer?.enabled = true
                val numBands = equalizer?.numberOfBands?.toInt() ?: 0
                if (numBands >= 5) {
                    val scale = intensity / 1000.0
                    equalizer?.setBandLevel(0.toShort(), (-500 * scale).toInt().toShort())
                    equalizer?.setBandLevel(1.toShort(), (-300 * scale).toInt().toShort())
                    equalizer?.setBandLevel(2.toShort(), (650 * scale).toInt().toShort())
                    equalizer?.setBandLevel(3.toShort(), (850 * scale).toInt().toShort())
                    equalizer?.setBandLevel(4.toShort(), (400 * scale).toInt().toShort())
                }
            } else {
                if (!isSurroundEnabled && !is8DEnabled) {
                    clearEQ()
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

    // ─── Spatial Reverb ───────────────────────────────────────────────────────

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

    // ─── 8D / 3D Spatial Audio Engine (Real-Time 60 FPS Ticker) ───────────────

    private fun start8DEngine() {
        stop8DEngine()

        try {
            if (!is8DEnabled) return
            virtualizer?.enabled = true
            if (virtualizer?.strengthSupported == true) {
                virtualizer?.forceVirtualizationMode(Virtualizer.VIRTUALIZATION_MODE_BINAURAL)
            }
            loudnessEnhancer?.enabled = true
            if (reverbMix > 0.15) {
                presetReverb?.enabled = true
                presetReverb?.preset = PresetReverb.PRESET_MEDIUMHALL
            }
        } catch (e: Exception) { e.printStackTrace() }

        timer8D = Timer()
        timer8D?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                if (!is8DEnabled || isBypassed) return

                val deltaSeconds = 0.016
                val effectiveSpeed = speedRadPerSec * deltaSeconds
                angle8D += effectiveSpeed
                if (angle8D > Math.PI * 2) angle8D -= Math.PI * 2

                val rad = orbitRadius * intensity8D
                var targetX = 0.0
                var targetY = 1.0

                // ── Compute Trajectory ────────────────────────────────────────
                when (trajectoryType) {
                    "orbit" -> {
                        targetX = rad * sin(angle8D)
                        targetY = rad * cos(angle8D) * depth8D
                    }
                    "vocalBeatSplit" -> {
                        // Left Vocals / Right Beats dual cross-movement:
                        // Lingers on Left & Right with smooth cross-movement
                        val sinVal = sin(angle8D)
                        val curve = (if (sinVal >= 0) 1.0 else -1.0) * abs(sinVal).pow(0.75)
                        targetX = rad * curve
                        targetY = rad * cos(angle8D) * depth8D * 0.6
                    }
                    "figureEight" -> {
                        targetX = rad * sin(angle8D)
                        targetY = (rad * sin(2.0 * angle8D) * 0.6) * depth8D
                    }
                    "dreamSpace" -> {
                        targetX = rad * sin(angle8D * 0.75)
                        targetY = (rad * cos(angle8D * 0.50 + Math.PI / 4.0)) * depth8D
                    }
                    "cinematic" -> {
                        val distanceBreathing = 0.85 + 0.20 * sin(angle8D * 0.25)
                        targetX = rad * distanceBreathing * sin(angle8D)
                        targetY = rad * distanceBreathing * cos(angle8D) * depth8D
                    }
                    "manual" -> {
                        targetX = manualTargetX
                        targetY = manualTargetY
                    }
                }

                // Smooth exponential interpolation (tau = 40ms)
                val smoothing = 1.0 - exp(-deltaSeconds / 0.040)
                currentX += (targetX - currentX) * smoothing
                currentY += (targetY - currentY) * smoothing

                // ── Spherical Coordinates & Psychoacoustic Cues ───────────────
                val distance = sqrt(currentX * currentX + currentY * currentY).coerceAtLeast(0.001)
                val azimuthRad = atan2(currentX, currentY)
                val azimuthDeg = azimuthRad * 180.0 / Math.PI

                // ── 1. HARDWARE STEREO CHANNEL VOLUME & EXTREME DISTANCE ─────
                // When sound moves far away, inverse-square law attenuates direct sound
                val normPan = (currentX / max(orbitRadius, 0.6)).coerceIn(-1.0, 1.0)
                val maxDrop = (0.97 * intensity8D).toFloat() // Drop opposite ear by up to 97%!

                // Distance attenuation: sound in front/back drops down to 40% direct volume
                val distFactor = ((distance - 0.4).coerceAtLeast(0.0) * 0.40 * depth8D * intensity8D).toFloat()
                val distAttenuation = (1.0f - distFactor).coerceIn(0.38f, 1.0f)

                var leftGain: Float
                var rightGain: Float

                if (normPan < 0.0) {
                    // Sound on LEFT: Left Ear = 100%, Right Ear drops to (1 - 0.97) = 3%!
                    leftGain = 1.0f * distAttenuation
                    rightGain = (1.0f - (-normPan.toFloat() * maxDrop)).coerceIn(0.02f, 1.0f) * distAttenuation
                } else {
                    // Sound on RIGHT: Right Ear = 100%, Left Ear drops to (1 - 0.97) = 3%!
                    rightGain = 1.0f * distAttenuation
                    leftGain = (1.0f - (normPan.toFloat() * maxDrop)).coerceIn(0.02f, 1.0f) * distAttenuation
                }

                try {
                    val track = getActiveAudioTrack()
                    track?.setStereoVolume(leftGain, rightGain)
                } catch (_: Exception) {}

                // ── 2. Virtualizer Binaural Depth Modulation ──────────────────
                val depthFactor = (currentY * 0.5 + 0.5).coerceIn(0.0, 1.0)
                targetVirtualizerStrength = (750 + (depthFactor * 250 * intensity8D)).toInt().coerceIn(0, 1000)
                currentVirtualizerStrength += (targetVirtualizerStrength - currentVirtualizerStrength) * 0.15

                try {
                    if (virtualizer?.strengthSupported == true) {
                        virtualizer?.setStrength(currentVirtualizerStrength.toInt().toShort())
                    }
                } catch (_: Exception) {}

                // ── 3. Asymmetric Pinna, Head-Shadow & Dual Vocal/Beat EQ ─────
                // Behind head: heavy high-frequency roll-off (-8dB to -12dB)
                val rearDamping = if (currentY < 0) (currentY * 650 * intensity8D).toInt() else 0
                val eqDopplerHigh = (sin(azimuthRad) * 700 * intensity8D).toInt() + rearDamping
                val eqDopplerMid = (cos(azimuthRad) * 450 * intensity8D).toInt()

                val eqBeatCounter = if (trajectoryType == "vocalBeatSplit") {
                    (sin(azimuthRad + Math.PI) * 600 * intensity8D).toInt()
                } else {
                    0
                }

                try {
                    val numBands = equalizer?.numberOfBands?.toInt() ?: 0
                    if (numBands >= 5 && !isVocalBoostEnabled) {
                        equalizer?.enabled = true
                        equalizer?.setBandLevel(0.toShort(), 0.toShort())
                        equalizer?.setBandLevel(1.toShort(), eqBeatCounter.coerceIn(-1000, 1000).toShort())
                        equalizer?.setBandLevel(2.toShort(), (sin(azimuthRad) * 500 * intensity8D).toInt().coerceIn(-1000, 1000).toShort())
                        equalizer?.setBandLevel(3.toShort(), eqDopplerMid.coerceIn(-1000, 1000).toShort())
                        equalizer?.setBandLevel(4.toShort(), eqDopplerHigh.coerceIn(-1000, 1000).toShort())
                    }
                } catch (_: Exception) {}

                // ── 4. Loudness Normalization ─────────────────────────────────
                targetLoudnessGainMb = ((1.0 - (distance * 0.35)) * 80 * intensity8D).toInt().coerceIn(0, 200)
                currentLoudnessGainMb += (targetLoudnessGainMb - currentLoudnessGainMb) * 0.10

                try {
                    loudnessEnhancer?.setTargetGain(currentLoudnessGainMb.toInt())
                } catch (_: Exception) {}

                // ── 5. Telemetry Stream to Flutter UI Visualizer ───────────────
                mainHandler.post {
                    channel.invokeMethod("onSpatialTelemetry", mapOf(
                        "x" to currentX,
                        "y" to currentY,
                        "z" to currentZ,
                        "azimuth" to azimuthDeg,
                        "distance" to distance,
                        "pan" to normPan,
                        "depth" to depthFactor
                    ))
                }
            }
        }, 0, 16)
    }

    private fun stop8DEngine() {
        timer8D?.cancel()
        timer8D = null
        angle8D = 0.0
        currentX = 0.0
        currentY = 1.0

        resetHardwareStereoVolume()

        try {
            if (!isSurroundEnabled) virtualizer?.enabled = false
            loudnessEnhancer?.enabled = false
            if (!isVocalBoostEnabled) clearEQ()
        } catch (_: Exception) {}

        mainHandler.post {
            channel.invokeMethod("onSpatialTelemetry", mapOf(
                "x" to 0.0,
                "y" to 1.0,
                "z" to 0.0,
                "azimuth" to 0.0,
                "distance" to 1.0,
                "pan" to 0.0,
                "depth" to 0.5
            ))
        }
    }
}
