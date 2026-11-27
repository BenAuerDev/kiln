package dev.bespokecode.kiln

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.concurrent.atomic.AtomicBoolean
import org.json.JSONException
import org.json.JSONObject

/**
 * Shared by the home-screen widgets. Their values come from Dart
 * (lib/features/home_widgets) through the home_widget package: one JSON
 * string per widget in its HomeWidgetPreferences, texts already in the app
 * language and colours as ARGB, plus a live flag per widget.
 *
 * A widget is live while Dart says its device is connected *and* kiln's
 * engine runs ([dispatcher]). Android can kill kiln without Dart noticing;
 * [goOffline] covers the engine going away, a swipe from recents while the
 * service runs and a fresh start. A kill without any of them leaves the last
 * drawing until the next tap, which redraws it offline.
 */
object KilnWidgets {
    const val PORTABLE_KEY = "portable"
    const val PORTABLE_LIVE_KEY = "portable_live"
    const val VOLCANO_KEY = "volcano"
    const val VOLCANO_LIVE_KEY = "volcano_live"

    private const val ACTION_BUTTON = "dev.bespokecode.kiln.WIDGET_BUTTON"
    private const val EXTRA_BUTTON = "button"
    private const val DISPATCH_TIMEOUT_MS = 8_000L

    /** From this height (dp) on, a widget shows its full two-row card. */
    private const val FULL_HEIGHT_DP = 100f

    /**
     * Set by MainActivity while its Flutter engine runs: hands a widget
     * button ("volcanoHeat", "portableBoost", …) to Dart over the
     * "dev.bespokecode.kiln/widgets" channel and calls `done` once Dart has
     * handled it. `null` while kiln is not running; the widgets then only
     * open kiln.
     */
    var dispatcher: ((action: String, done: () -> Unit) -> Unit)? = null

    /**
     * kiln's Dart side is gone or about to go (or starts fresh): no widget
     * may look live, whatever Dart stored last.
     */
    fun goOffline(context: Context) {
        dispatcher = null
        HomeWidgetPlugin.getData(context).edit()
            .putBoolean(PORTABLE_LIVE_KEY, false)
            .putBoolean(VOLCANO_LIVE_KEY, false)
            .commit()
        PortableWidgetProvider.refresh(context)
        VolcanoWidgetProvider.refresh(context)
    }

    /**
     * Puts the right layout on widget [id]: the compact one-row card at
     * 4×1, the full card from two rows. Android 12+ picks between both
     * itself as the widget is resized; below that, [build] runs again from
     * onAppWidgetOptionsChanged. [build] gets the portrait width in dp
     * (0 when the launcher does not tell).
     */
    fun update(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        build: (compact: Boolean, widthDp: Int) -> RemoteViews,
    ) {
        val options = manager.getAppWidgetOptions(id)
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            RemoteViews(
                mapOf(
                    SizeF(0f, 0f) to build(true, width),
                    SizeF(0f, FULL_HEIGHT_DP) to build(false, width),
                ),
            )
        } else {
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
            build(height in 1 until FULL_HEIGHT_DP.toInt(), width)
        }
        manager.updateAppWidget(id, views)
    }

    fun live(data: SharedPreferences, key: String): Boolean =
        data.getBoolean(key, false) && dispatcher != null

    fun json(data: SharedPreferences, key: String): JSONObject? {
        val raw = data.getString(key, null) ?: return null
        return try {
            JSONObject(raw)
        } catch (e: JSONException) {
            null
        }
    }

    /** ARGB from Dart; values above 2^31 arrive as Long. */
    fun JSONObject.color(key: String): Int? =
        if (has(key)) optLong(key).toInt() else null

    fun openKiln(context: Context, requestCode: Int): PendingIntent =
        PendingIntent.getActivity(
            context,
            requestCode,
            openIntent(context),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    private fun openIntent(context: Context): Intent =
        Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)

    /** Widget colours of a JSON value, with fallbacks for older stored values. */
    class Colors(context: Context, values: JSONObject) {
        val text = context.getColor(R.color.widget_text)
        val muted = context.getColor(R.color.widget_muted)
        val low = context.getColor(R.color.widget_low)
        val accent = values.color("accent") ?: text
        val accentText = values.color("accentText") ?: accent
        val onAccent = values.color("onAccent") ?: context.getColor(R.color.widget_background)
        val gradientStart = values.color("gradientStart") ?: accent
        val gradientEnd = values.color("gradientEnd") ?: accent
    }

    /**
     * A Heat / Air / Boost button: raised, or filled with the accent while
     * [active]. Live, a tap is a broadcast to [provider] (see [onButton]);
     * offline it opens kiln.
     */
    fun bindButton(
        context: Context,
        views: RemoteViews,
        provider: Class<out BroadcastReceiver>,
        ids: ButtonIds,
        label: String,
        active: Boolean,
        live: Boolean,
        colors: Colors,
        action: String,
        requestCode: Int,
        open: PendingIntent,
    ) {
        views.setTextViewText(ids.label, label)
        views.setTextColor(ids.label, if (active) colors.onAccent else colors.text)
        views.setViewVisibility(ids.filled, if (active) View.VISIBLE else View.GONE)
        views.setInt(ids.filled, "setColorFilter", colors.accent)
        val click = if (live) {
            PendingIntent.getBroadcast(
                context,
                requestCode,
                Intent(context, provider).setAction(ACTION_BUTTON).putExtra(EXTRA_BUTTON, action),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        } else {
            open
        }
        views.setOnClickPendingIntent(ids.root, click)
    }

    class ButtonIds(val root: Int, val filled: Int, val label: Int)

    /**
     * Runs a button broadcast from [bindButton]; `false` for any other
     * intent. Hands it to Dart and holds the broadcast (goAsync) until Dart
     * has sent the write, so a cached, frozen kiln wakes up for it. Without
     * kiln it redraws the widgets offline and tries to open kiln (Android
     * may drop that start from the background; then the redrawn widget opens
     * it on the next tap).
     */
    fun onButton(receiver: BroadcastReceiver, context: Context, intent: Intent): Boolean {
        if (intent.action != ACTION_BUTTON) return false
        val action = intent.getStringExtra(EXTRA_BUTTON) ?: return true
        val dispatch = dispatcher
        if (dispatch != null) {
            val pending = receiver.goAsync()
            val finished = AtomicBoolean(false)
            val finish = { if (finished.compareAndSet(false, true)) pending.finish() }
            Handler(Looper.getMainLooper()).postDelayed(finish, DISPATCH_TIMEOUT_MS)
            dispatch(action, finish)
            return true
        }
        PortableWidgetProvider.refresh(context)
        VolcanoWidgetProvider.refresh(context)
        context.startActivity(openIntent(context).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        return true
    }

    /**
     * A square bitmap with the app's 270° gauge (kiln_gauge_painter.dart):
     * the track, then the [start] → [end] gradient arc up to [progress] (0–1).
     */
    fun gauge(context: Context, sizeDp: Float, progress: Float, start: Int, end: Int): Bitmap {
        val size = px(context, sizeDp)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val stroke = size / 12f
        val inset = stroke / 2 + 1
        val rect = RectF(inset, inset, size - inset, size - inset)
        val paint = strokePaint(stroke, context.getColor(R.color.widget_track))
        canvas.drawArc(rect, 135f, 270f, false, paint)
        val sweep = 270f * progress.coerceIn(0f, 1f)
        if (sweep > 0f) {
            paint.shader = LinearGradient(
                0f, size.toFloat(), size.toFloat(), 0f,
                start, end, Shader.TileMode.CLAMP,
            )
            canvas.drawArc(rect, 135f, sweep, false, paint)
        }
        return bitmap
    }

    fun strokePaint(width: Float, color: Int) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = width
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
        this.color = color
    }

    /**
     * Pixels for [dp], at most 2x: a RemoteViews bitmap travels through a
     * binder call on every update.
     */
    fun px(context: Context, dp: Float): Int =
        (dp * context.resources.displayMetrics.density.coerceAtMost(2f)).toInt().coerceAtLeast(1)

    fun density(context: Context): Float = context.resources.displayMetrics.density.coerceAtMost(2f)
}
