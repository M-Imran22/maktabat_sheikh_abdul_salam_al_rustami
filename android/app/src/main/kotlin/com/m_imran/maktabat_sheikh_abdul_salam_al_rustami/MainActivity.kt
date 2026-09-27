package com.m_imran.maktabat_sheikh_abdul_salam_al_rustami

import android.content.Intent
import android.net.Uri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.shaikhrustami.maktabat/app_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
