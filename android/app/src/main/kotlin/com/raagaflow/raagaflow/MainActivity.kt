package com.raagaflow.raagaflow

import io.flutter.embedding.engine.FlutterEngine
import com.ryanheise.audioservice.AudioServiceFragmentActivity

class MainActivity : AudioServiceFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AudioEffectsPlugin(flutterEngine)
    }
}
