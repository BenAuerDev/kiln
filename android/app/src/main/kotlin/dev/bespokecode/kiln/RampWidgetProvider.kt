package dev.bespokecode.kiln

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * Venty/Veazy ramp home-screen widget: a ring that fills step by step with
 * the base inside, the ramp's name and where it stands, a countdown to the
 * next step and Start / Stop. The countdown is a [android.widget.Chronometer],
 * so it ticks without kiln redrawing the widget; kiln sends a new one with
 * every step. One row at 4×1, the full card from two rows. Live and offline
 * as described in [KilnWidgets]; offline the ring empties, the countdown
 * goes and a tap anywhere opens kiln.
 */
class RampWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { draw(context, appWidgetManager, it, widgetData) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        draw(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (!KilnWidgets.onButton(this, context, intent)) super.onReceive(context, intent)
    }

    companion object {
        private const val OPEN_REQUEST = 20
        private const val TOGGLE_REQUEST = 21
        private const val GAUGE_DP = 88f
        private const val COMPACT_GAUGE_DP = 52f

        /**
         * The countdown ends this much after the step is due. A Chronometer
         * cannot stop at zero and would show "−0:01" until kiln redraws:
         * the ramp checks once a second, then writes over Bluetooth and
         * sends the new widget values.
         */
        private const val COUNTDOWN_SLACK_MS = 1_500L

        /** Redraws the widget, e.g. when kiln's engine comes or goes. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, RampWidgetProvider::class.java))
            val data = HomeWidgetPlugin.getData(context)
            ids.forEach { draw(context, manager, it, data) }
        }

        private fun draw(context: Context, manager: AppWidgetManager, id: Int, data: SharedPreferences) =
            KilnWidgets.update(context, manager, id) { compact, _ -> views(context, data, compact) }

        private fun views(context: Context, data: SharedPreferences, compact: Boolean): RemoteViews {
            val views = RemoteViews(
                context.packageName,
                if (compact) R.layout.widget_ramp_compact else R.layout.widget_ramp,
            )
            val open = KilnWidgets.openKiln(context, OPEN_REQUEST)
            views.setOnClickPendingIntent(R.id.widget_root, open)
            val values = KilnWidgets.json(data, KilnWidgets.RAMP_KEY)
            views.setViewVisibility(R.id.widget_content, if (values != null) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.widget_empty, if (values != null) View.GONE else View.VISIBLE)
            if (values == null) return views

            val live = KilnWidgets.live(data, KilnWidgets.RAMP_LIVE_KEY)
            val colors = KilnWidgets.Colors(context, values)
            fun text(liveKey: String, offlineKey: String) = values.optString(if (live) liveKey else offlineKey)

            views.setTextViewText(R.id.widget_name, values.optString("name"))
            views.setTextViewText(R.id.widget_center, values.optString("center"))
            views.setTextColor(R.id.widget_center, if (live) colors.text else colors.muted)
            views.setTextViewText(R.id.widget_status, text("status", "offlineStatus"))
            views.setTextColor(
                R.id.widget_status,
                if (live && values.optBoolean("statusAccent")) colors.accentText else colors.muted,
            )
            val progress = if (live) values.optDouble("progress", 0.0).toFloat() else 0f
            views.setImageViewBitmap(
                R.id.widget_gauge,
                KilnWidgets.gauge(
                    context,
                    if (compact) COMPACT_GAUGE_DP else GAUGE_DP,
                    progress,
                    colors.gradientStart,
                    colors.gradientEnd,
                ),
            )
            views.setContentDescription(R.id.widget_gauge, text("gaugeDescription", "offlineStatus"))

            val counting = bindCountdown(views, values, live)
            views.setTextColor(R.id.widget_countdown, colors.accentText)
            // One row has room for either the status or the countdown.
            if (compact) {
                views.setViewVisibility(R.id.widget_status, if (counting) View.GONE else View.VISIBLE)
            }

            KilnWidgets.bindButton(
                context, views, RampWidgetProvider::class.java,
                KilnWidgets.ButtonIds(R.id.widget_toggle, R.id.widget_toggle_filled, R.id.widget_toggle_label),
                label = text("buttonLabel", "offlineButtonLabel"),
                active = live && values.optBoolean("buttonActive"),
                live = live, colors = colors,
                action = "rampToggle", requestCode = TOGGLE_REQUEST, open = open,
            )
            return views
        }

        /**
         * Counts down to `nextStepAtMillis` with `countdownFormat` ("190° in
         * %s") while live and a step is due; `false` (hidden) otherwise. The
         * chronometer runs on the elapsed-realtime clock, so the wall-clock
         * time from Dart is turned into an offset from now, plus
         * [COUNTDOWN_SLACK_MS]. Dart drops the countdown while a step write
         * keeps failing, so it does not run on below zero then.
         */
        private fun bindCountdown(views: RemoteViews, values: JSONObject, live: Boolean): Boolean {
            val format = values.optString("countdownFormat")
            val dueAt = values.optLong("nextStepAtMillis", 0L)
            val counting = live && format.isNotEmpty() && dueAt > 0L
            if (counting) {
                val base = SystemClock.elapsedRealtime() +
                    (dueAt + COUNTDOWN_SLACK_MS - System.currentTimeMillis())
                views.setChronometer(R.id.widget_countdown, base, format, true)
                views.setChronometerCountDown(R.id.widget_countdown, true)
            } else {
                views.setChronometer(R.id.widget_countdown, SystemClock.elapsedRealtime(), null, false)
            }
            views.setViewVisibility(R.id.widget_countdown, if (counting) View.VISIBLE else View.GONE)
            return counting
        }
    }
}
