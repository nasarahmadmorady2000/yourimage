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

            // =========================
            // WALLPAPER METHOD
            // =========================
            if (call.method == "setWallpaper") {

                val path = call.argument<String>("imagePath")
                val type = call.argument<String>("type") ?: "both"

                if (path == null) {
                    result.error("ERROR", "Image path is null", null)
                    return@setMethodCallHandler
                }

                try {
                    val file = File(path)

                    if (!file.exists()) {
                        result.error("NOT_FOUND", "File not found", null)
                        return@setMethodCallHandler
                    }

                    val bitmap = BitmapFactory.decodeFile(file.absolutePath)

                    val wallpaperManager = WallpaperManager.getInstance(this)

                    // =========================
                    // APPLY WALLPAPER LOGIC
                    // =========================
                    when (type) {

                        // 📱 Home Screen only
                        "home" -> {
                            wallpaperManager.setBitmap(
                                bitmap,
                                null,
                                true,
                                WallpaperManager.FLAG_SYSTEM
                            )
                        }

                        // 🔒 Lock Screen only
                        "lock" -> {
                            wallpaperManager.setBitmap(
                                bitmap,
                                null,
                                true,
                                WallpaperManager.FLAG_LOCK
                            )
                        }

                        // 📱 Both screens
                        else -> {
                            wallpaperManager.setBitmap(bitmap)
                        }
                    }

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