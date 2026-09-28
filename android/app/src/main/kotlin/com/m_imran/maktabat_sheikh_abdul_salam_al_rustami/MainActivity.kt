package com.m_imran.maktabat_sheikh_abdul_salam_al_rustami

import android.content.Intent
import android.net.Uri
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.shaikhrustami.maktabat/app_launcher"
    private val SCREEN_SECURITY_CHANNEL = "com.shaikhrustami.maktabat/screen_security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_SECURITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setPdfSecure" -> {
                        val enabled = call.argument<Boolean>("enabled")
                        if (enabled == null) {
                            result.error("INVALID_ARGUMENT", "enabled is required", null)
                        } else {
                            if (enabled) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchAppOrStore" -> {
                    val packageName = call.argument<String>("package") ?: "com.m_imran.tafsir_ahsan_al_kalam"
                    val storeUrl = call.argument<String>("storeUrl") ?: "https://play.google.com/store/apps/details?id=$packageName"

                    val pm = packageManager
                    val launchIntent = pm.getLaunchIntentForPackage(packageName)
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launchIntent)
                        result.success(true) // App was installed and launched
                    } else {
                        // Not installed, open Play Store or browser fallback
                        try {
                            val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName")).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(marketIntent)
                            result.success(false) // Redirected to Play Store app
                        } catch (e: Exception) {
                            val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse(storeUrl)).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(webIntent)
                            result.success(false) // Redirected to Web Play Store
                        }
                    }
                }
                "isAppInstalled" -> {
                    val packageName = call.argument<String>("package") ?: "com.m_imran.tafsir_ahsan_al_kalam"
                    val pm = packageManager
                    val launchIntent = pm.getLaunchIntentForPackage(packageName)
                    result.success(launchIntent != null)
                }
                "shareApp" -> {
                    val message = call.argument<String>("message")?.trim().orEmpty()
                    if (message.isEmpty()) {
                        result.error("INVALID_ARGUMENT", "message is required", null)
                    } else {
                        val url = "https://play.google.com/store/apps/details?id=$packageName"
                        val sendIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, "$message\n$url")
                        }
                        try {
                            startActivity(Intent.createChooser(sendIntent, null))
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("SHARE_FAILED", error.message, null)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
