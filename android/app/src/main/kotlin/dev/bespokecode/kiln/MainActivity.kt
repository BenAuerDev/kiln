package dev.bespokecode.kiln

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::onBackgroundCall)
    }

    private fun onBackgroundCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "update" -> {
                // Same id as the foreground notification: replaces it without
                // restarting the service, which Android 12+ refuses from the background.
                getSystemService(NotificationManager::class.java).notify(
                    KilnSessionService.SESSION_ID,
                    KilnSessionService.sessionNotification(
                        this,
                        call.argument<String>("title") ?: "",
                        call.argument<String>("text") ?: "",
                    ),
                )
                result.success(null)
            }
            "start" -> {
                KilnSessionService.createChannels(
                    this,
                    call.argument<String>("sessionChannel") ?: "",
                    call.argument<String>("readyChannel") ?: "",
                )
                val intent = Intent(this, KilnSessionService::class.java)
                    .putExtra(KilnSessionService.EXTRA_TITLE, call.argument<String>("title"))
                    .putExtra(KilnSessionService.EXTRA_TEXT, call.argument<String>("text"))
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                } catch (e: IllegalStateException) {
                    // Android 12+ refuses to start a foreground service from the background.
                    result.error("not_allowed", e.message, null)
                }
            }
            "stop" -> {
                // Through the service's own queue, so a stop right after a
                // start cannot overtake its startForeground().
                try {
                    startService(
                        Intent(this, KilnSessionService::class.java)
                            .setAction(KilnSessionService.ACTION_STOP),
                    )
                } catch (e: IllegalStateException) {
                    stopService(Intent(this, KilnSessionService::class.java))
                }
                result.success(null)
            }
            "cancelAlert" -> {
                getSystemService(NotificationManager::class.java)
                    .cancel(KilnSessionService.READY_ID)
                result.success(null)
            }
            "alert" -> {
                KilnSessionService.createChannels(
                    this,
                    call.argument<String>("sessionChannel") ?: "",
                    call.argument<String>("readyChannel") ?: "",
                )
                getSystemService(NotificationManager::class.java).notify(
                    KilnSessionService.READY_ID,
                    KilnSessionService.readyNotification(
                        this,
                        call.argument<String>("title") ?: "",
                        call.argument<String>("text") ?: "",
                    ),
                )
                result.success(null)
            }
            "requestNotificationPermission" -> requestNotificationPermission(result)
            else -> result.notImplemented()
        }
    }

    override fun onDestroy() {
        // Back on the root screen finishes the activity and with it the Dart
        // engine and the Bluetooth link: nothing is left for the service to
        // keep alive. (A swipe from recents is covered by stopWithTask.)
        if (isFinishing) stopService(Intent(this, KilnSessionService::class.java))
        super.onDestroy()
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        pendingPermission?.success(false)
        pendingPermission = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NOTIFICATION_REQUEST) return
        pendingPermission?.success(
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
        )
        pendingPermission = null
    }

    companion object {
        private const val CHANNEL = "dev.bespokecode.kiln/background"
        private const val NOTIFICATION_REQUEST = 1001
    }
}
