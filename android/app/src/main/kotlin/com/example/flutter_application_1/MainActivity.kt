package com.example.flutter_application_1

import android.app.WallpaperManager
import android.graphics.BitmapFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.imagesapp.wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "setWallpaper") {

                val imagePath = call.argument<String>("imagePath")

                if (imagePath == null) {
                    result.error("INVALID", "Image path is null", null)
                    return@setMethodCallHandler
                }

                try {
                    val file = File(imagePath)

                    if (!file.exists()) {
                        result.error("NOT_FOUND", "Image file not found", null)
                        return@setMethodCallHandler
                    }

                    val bitmap = BitmapFactory.decodeFile(file.absolutePath)

                    val wallpaperManager = WallpaperManager.getInstance(this)

                    // Apply wallpaper (HOME SCREEN + LOCK SCREEN)
                    wallpaperManager.setBitmap(bitmap)

                    result.success(true)

                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}