package dev.bespokecode.kiln

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * Venty/Veazy home-screen widget, the counterpart of the Volcano's wide
 * card: a battery ring holding the device's line drawing, status, the
 * base → boost → superboost ladder and Heat / Boost. At 4×1 it is one
 * row (the ladder as three temperatures); from two rows the full card.
 * Live and offline as described in [KilnWidgets]; offline it keeps the
 * last values (the battery ring turns grey) and a tap anywhere opens kiln.
 */
class PortableWidgetProvider : HomeWidgetProvider() {
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
        // Resized: the ladder bar is drawn for the new width (and below
        // Android 12 the layout is picked for the new height).
        draw(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (!KilnWidgets.onButton(this, context, intent)) super.onReceive(context, intent)
    }

    companion object {
        private const val OPEN_REQUEST = 1
        private const val HEAT_REQUEST = 2
        private const val BOOST_REQUEST = 3
        private const val RING_DP = 88f
        private const val COMPACT_RING_DP = 52f
        private const val LADDER_HEIGHT_DP = 14f

        /** Padding, ring and gap next to the ladder (widget_portable.xml). */
        private const val LADDER_INSET_DP = 18 + 18 + 88 + 16
        private const val LADDER_FALLBACK_DP = 170

        /** Redraws the widget, e.g. when kiln's engine comes or goes. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PortableWidgetProvider::class.java))
            val data = HomeWidgetPlugin.getData(context)
            ids.forEach { draw(context, manager, it, data) }
        }

        private fun draw(context: Context, manager: AppWidgetManager, id: Int, data: SharedPreferences) =
            KilnWidgets.update(context, manager, id) { compact, width ->
                val ladderWidth = (width - LADDER_INSET_DP).takeIf { it > 40 } ?: LADDER_FALLBACK_DP
                views(context, data, compact, ladderWidth.toFloat())
            }

        private fun views(
            context: Context,
            data: SharedPreferences,
            compact: Boolean,
            ladderWidthDp: Float,
        ): RemoteViews {
            val views = RemoteViews(
                context.packageName,
                if (compact) R.layout.widget_portable_compact else R.layout.widget_portable,
            )
            val open = KilnWidgets.openKiln(context, OPEN_REQUEST)
            views.setOnClickPendingIntent(R.id.widget_root, open)
            val values = KilnWidgets.json(data, KilnWidgets.PORTABLE_KEY)
            views.setViewVisibility(R.id.widget_content, if (values != null) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.widget_empty, if (values != null) View.GONE else View.VISIBLE)
            if (values == null) return views

            val live = KilnWidgets.live(data, KilnWidgets.PORTABLE_LIVE_KEY)
            val colors = KilnWidgets.Colors(context, values)
            fun text(key: String) = values.optString(key)
            fun text(liveKey: String, offlineKey: String) = text(if (live) liveKey else offlineKey)

            views.setImageViewBitmap(R.id.widget_ring, ring(context, values, live, colors, compact))
            views.setContentDescription(R.id.widget_ring, text("ringDescription"))
            views.setTextViewText(R.id.widget_battery, text("battery"))
            views.setTextColor(R.id.widget_battery, if (live) colors.text else colors.muted)

            views.setTextViewText(R.id.widget_name, text("name"))
            views.setTextViewText(R.id.widget_status, text("status", "offlineStatus"))
            views.setTextColor(
                R.id.widget_status,
                if (live && values.optBoolean("statusAccent")) colors.accentText else colors.muted,
            )

            views.setTextViewText(R.id.widget_base, text("base"))
            views.setTextViewText(R.id.widget_boost, text("boost"))
            views.setTextViewText(R.id.widget_super, text("superBoost"))
            if (compact) {
                views.setContentDescription(R.id.widget_steps, text("ladderDescription"))
            } else {
                views.setImageViewBitmap(R.id.widget_ladder, ladder(context, values, ladderWidthDp, colors))
                views.setContentDescription(R.id.widget_ladder, text("ladderDescription"))
                views.setTextViewText(R.id.widget_base_label, text("baseLabel"))
                views.setTextViewText(R.id.widget_boost_label, text("boostLabel"))
                views.setTextViewText(R.id.widget_super_label, text("superLabel"))
            }
            views.setTextColor(R.id.widget_boost, colors.accentText)
            views.setTextColor(R.id.widget_super, colors.accentText)

            KilnWidgets.bindButton(
                context, views, PortableWidgetProvider::class.java,
                KilnWidgets.ButtonIds(R.id.widget_heat, R.id.widget_heat_filled, R.id.widget_heat_label),
                label = text("heatLabel", "offlineHeatLabel"),
                active = live && values.optBoolean("heatActive"),
                live = live, colors = colors,
                action = "portableHeat", requestCode = HEAT_REQUEST, open = open,
            )
            KilnWidgets.bindButton(
                context, views, PortableWidgetProvider::class.java,
                KilnWidgets.ButtonIds(R.id.widget_boost_button, R.id.widget_boost_filled, R.id.widget_boost_button_label),
                label = text("boostButtonLabel", "offlineBoostLabel"),
                active = live && values.optBoolean("boostActive"),
                live = live, colors = colors,
                action = "portableBoost", requestCode = BOOST_REQUEST, open = open,
            )
            return views
        }

        /**
         * The battery gauge (grey while offline) with the device's line
         * drawing inside; the full card has the % in the gap below it.
         */
        private fun ring(
            context: Context,
            values: JSONObject,
            live: Boolean,
            colors: KilnWidgets.Colors,
            compact: Boolean,
        ): Bitmap {
            val level = values.optDouble("batteryLevel", 0.0).toFloat()
            val bitmap = KilnWidgets.gauge(
                context, if (compact) COMPACT_RING_DP else RING_DP, level,
                if (live) colors.gradientStart else colors.muted,
                if (live) colors.gradientEnd else colors.muted,
            )
            val size = bitmap.width.toFloat()
            val centre = if (compact) size * 0.5f else size * 0.45f
            glyph(Canvas(bitmap), values.optString("glyph"), size * 0.46f, size / 2, centre, colors.accent)
            return bitmap
        }

        /**
         * The line drawings of device_glyph_painter.dart, on its 40×40 grid,
         * [box] wide and centred on ([cx], [cy]).
         */
        private fun glyph(canvas: Canvas, model: String, box: Float, cx: Float, cy: Float, color: Int) {
            val unit = box / 40f
            canvas.save()
            canvas.translate(cx - box / 2, cy - box / 2)
            canvas.scale(unit, unit)
            val paint = KilnWidgets.strokePaint(2.2f, color)
            if (model == "venty") {
                canvas.drawRoundRect(RectF(13f, 5f, 27f, 35f), 7f, 7f, paint)
                canvas.drawCircle(20f, 13f, 3f, paint)
            } else {
                canvas.drawRoundRect(RectF(11f, 8f, 29f, 34f), 9f, 9f, paint)
                canvas.drawCircle(20f, 16f, 3f, paint)
            }
            canvas.drawLine(17f, 26f, 23f, 26f, paint)
            canvas.restore()
        }

        /**
         * The Setup tab's scale bar: 40–210 °C track, the base → superboost
         * range in the gradient, a dot per step (base in the text colour).
         */
        private fun ladder(context: Context, values: JSONObject, widthDp: Float, colors: KilnWidgets.Colors): Bitmap {
            val density = KilnWidgets.density(context)
            val width = KilnWidgets.px(context, widthDp)
            val height = KilnWidgets.px(context, LADDER_HEIGHT_DP)
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val radius = 4.5f * density
            val outline = 2f * density
            val track = 6f * density
            val y = height / 2f
            fun x(key: String) = radius + values.optDouble(key, 0.0).toFloat().coerceIn(0f, 1f) * (width - 2 * radius)

            val line = KilnWidgets.strokePaint(track, context.getColor(R.color.widget_track))
            canvas.drawLine(track / 2, y, width - track / 2, y, line)
            val base = x("basePosition")
            val superBoost = x("superBoostPosition")
            if (superBoost > base) {
                line.shader = LinearGradient(base, 0f, superBoost, 0f, colors.gradientStart, colors.gradientEnd, Shader.TileMode.CLAMP)
                canvas.drawLine(base, y, superBoost, y, line)
            }
            val fill = Paint(Paint.ANTI_ALIAS_FLAG)
            val ring = KilnWidgets.strokePaint(outline, context.getColor(R.color.widget_background))
            listOf(
                base to colors.text,
                x("boostPosition") to colors.accent,
                superBoost to colors.accent,
            ).forEach { (cx, color) ->
                fill.color = color
                canvas.drawCircle(cx, y, radius - outline / 2, fill)
                canvas.drawCircle(cx, y, radius - outline / 2, ring)
            }
            return bitmap
        }
    }
}
