package com.example.smart_hajj_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var pendingIntent: Intent? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "guardian/background_location").setMethodCallHandler { call, result ->
            when (call.method) {
                "language" -> { LocationSharingService.active?.updateLanguage(call.argument<String>("language") ?: "en"); result.success(null) }
                "status" -> result.success(mapOf("running" to LocationSharingService.running, "phone" to LocationSharingService.phone, "message" to LocationSharingService.message, "receipt" to LocationSharingService.receipt))
                "stop" -> { stopService(Intent(this, LocationSharingService::class.java)); result.success(null) }
                "start" -> {
                    if (pending != null) { result.error("BUSY", "Permission request in progress", null); return@setMethodCallHandler }
                    val intent = Intent(this, LocationSharingService::class.java)
                        .putExtra("phone", call.argument<String>("phone"))
                        .putExtra("baseUrl", call.argument<String>("baseUrl"))
                        .putExtra("language", call.argument<String>("language"))
                    if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                        pending = result; pendingIntent = intent
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2401)
                    } else launchSharing(intent, result)
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun launchSharing(intent: Intent, result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
            result.success(null)
        } catch (e: Exception) { result.error("START_FAILED", "Open the app and enable location permission to start sharing.", null) }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 2401) {
            val result = pending; val intent = pendingIntent; pending = null; pendingIntent = null
            if (result != null && intent != null) {
                if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) launchSharing(intent, result)
                else result.error("NOTIFICATIONS_DENIED", "Allow notifications so you can see and stop background sharing.", null)
            }
        }
    }
}
