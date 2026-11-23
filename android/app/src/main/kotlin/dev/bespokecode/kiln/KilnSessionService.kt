package dev.bespokecode.kiln

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Keeps kiln's process at foreground priority while a heater is on, so the
 * Bluetooth connection and the Dart code driving it keep running in the
 * background. It holds no logic: Dart starts, updates and stops it through
 * the "dev.bespokecode.kiln/background" method channel (MainActivity).
 *
 * Swiping kiln away from recents ends it (stopWithTask in the manifest).
 */
class KilnSessionService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            // Only if no newer start is queued: that one still owes
            // startForeground(), and stopping now would crash it.
            stopSelf(startId)
            return START_NOT_STICKY
        }
        val notification = sessionNotification(
            this,
            intent?.getStringExtra(EXTRA_TITLE) ?: "",
            intent?.getStringExtra(EXTRA_TEXT) ?: "",
        )
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    SESSION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
                )
            } else {
                startForeground(SESSION_ID, notification)
            }
        } catch (e: SecurityException) {
            // Android 14+: a connectedDevice service needs the Bluetooth
            // permission. Without it there is nothing to keep alive anyway.
            stopSelf()
        }
        return START_NOT_STICKY
    }

    companion object {
        const val ACTION_STOP = "dev.bespokecode.kiln.STOP_SESSION"
        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val SESSION_CHANNEL = "session"
        const val READY_CHANNEL = "ready"
        const val SESSION_ID = 1
        const val READY_ID = 2

        /** Channel names are user-visible in the system settings, so they come from Dart's .arb files. */
        fun createChannels(context: Context, sessionName: String, readyName: String) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(SESSION_CHANNEL, sessionName, NotificationManager.IMPORTANCE_LOW),
            )
            manager.createNotificationChannel(
                NotificationChannel(READY_CHANNEL, readyName, NotificationManager.IMPORTANCE_HIGH),
            )
        }

        fun sessionNotification(context: Context, title: String, text: String): Notification =
            builder(context, SESSION_CHANNEL)
                .setContentTitle(title)
                .setContentText(text)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .build()

        fun readyNotification(context: Context, title: String, text: String): Notification =
            builder(context, READY_CHANNEL)
                .setContentTitle(title)
                .setContentText(text)
                .setAutoCancel(true)
                .build()

        @Suppress("DEPRECATION")
        private fun builder(context: Context, channel: String): Notification.Builder {
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, channel)
            } else {
                Notification.Builder(context)
            }
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            return builder
                .setSmallIcon(R.drawable.ic_stat_kiln)
                .setContentIntent(open)
                .setShowWhen(false)
        }
    }
}
