package dev.bespokecode.kiln

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Volcano home-screen widget (design/Widgets.dc.html, wide card): gauge
 * with the live temperature, status, Heat and Air; one row at 4×1, the
 * full card from two rows. Live and offline as described in
 * [KilnWidgets]; offline, a tap anywhere opens kiln.
 */
class VolcanoWidgetProvider : HomeWidgetProvider() {
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
        private const val OPEN_REQUEST = 10
        private const val HEAT_REQUEST = 11
        private const val AIR_REQUEST = 12
        private const val GAUGE_DP = 88f
        private const val COMPACT_GAUGE_DP = 52f

        /** Redraws the widget, e.g. when kiln's engine comes or goes. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, VolcanoWidgetProvider::class.java))
            val data = HomeWidgetPlugin.getData(context)
            ids.forEach { draw(context, manager, it, data) }
        }

        private fun draw(context: Context, manager: AppWidgetManager, id: Int, data: SharedPreferences) =
            KilnWidgets.update(context, manager, id) { compact, _ -> views(context, data, compact) }

        private fun views(context: Context, data: SharedPreferences, compact: Boolean): RemoteViews {
            val views = RemoteViews(
                context.packageName,
                if (compact) R.layout.widget_volcano_compact else R.layout.widget_volcano,
            )
            val open = KilnWidgets.openKiln(context, OPEN_REQUEST)
            views.setOnClickPendingIntent(R.id.widget_root, open)
            val values = KilnWidgets.json(data, KilnWidgets.VOLCANO_KEY)
            views.setViewVisibility(R.id.widget_content, if (values != null) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.widget_empty, if (values != null) View.GONE else View.VISIBLE)
            if (values == null) return views

            val live = KilnWidgets.live(data, KilnWidgets.VOLCANO_LIVE_KEY)
            val colors = KilnWidgets.Colors(context, values)
            fun text(liveKey: String, offlineKey: String) = values.optString(if (live) liveKey else offlineKey)

            views.setTextViewText(R.id.widget_name, values.optString("name"))
            views.setTextViewText(R.id.widget_temperature, text("temperature", "offlineTemperature"))
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
            KilnWidgets.bindButton(
                context, views, VolcanoWidgetProvider::class.java,
                KilnWidgets.ButtonIds(R.id.widget_heat, R.id.widget_heat_filled, R.id.widget_heat_label),
                label = text("heatLabel", "offlineHeatLabel"),
                active = live && values.optBoolean("heatActive"),
                live = live, colors = colors,
                action = "volcanoHeat", requestCode = HEAT_REQUEST, open = open,
            )
            KilnWidgets.bindButton(
                context, views, VolcanoWidgetProvider::class.java,
                KilnWidgets.ButtonIds(R.id.widget_air, R.id.widget_air_filled, R.id.widget_air_label),
                label = text("airLabel", "offlineAirLabel"),
                active = live && values.optBoolean("airActive"),
                live = live, colors = colors,
                action = "volcanoAir", requestCode = AIR_REQUEST, open = open,
            )
            return views
        }
    }
}
