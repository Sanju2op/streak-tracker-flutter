package com.sanju2op.streaktracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

open class CounterWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val countersJson = widgetData.getString("counters_json", "[]")
        
        try {
            val array = JSONArray(countersJson)
            
            appWidgetIds.forEach { widgetId ->
                val selectedId = widgetData.getString("widget_id_$widgetId", null)
                val counterToDisplay = if (selectedId != null) {
                    var found: JSONObject? = null
                    for (i in 0 until array.length()) {
                        val obj = array.getJSONObject(i)
                        if (obj.getString("id") == selectedId) {
                            found = obj
                            break
                        }
                    }
                    found ?: if (array.length() > 0) array.getJSONObject(0) else null
                } else {
                    if (array.length() > 0) array.getJSONObject(0) else null
                }

                if (this@CounterWidgetProvider is CounterWidgetProviderMedium) {
                    val views = RemoteViews(context.packageName, R.layout.widget_medium)
                    if (array.length() > 0) bindItem(views, array, 0, R.id.item1, R.id.tv_title1, R.id.tv_count1, R.id.tv_unit1)
                    if (array.length() > 1) bindItem(views, array, 1, R.id.item2, R.id.tv_title2, R.id.tv_count2, R.id.tv_unit2)
                    if (array.length() > 2) bindItem(views, array, 2, R.id.item3, R.id.tv_title3, R.id.tv_count3, R.id.tv_unit3)
                    if (array.length() > 3) bindItem(views, array, 3, R.id.item4, R.id.tv_title4, R.id.tv_count4, R.id.tv_unit4)
                    appWidgetManager.updateAppWidget(widgetId, views)
                } else if (this@CounterWidgetProvider is CounterWidgetProviderRounded) {
                    val views = RemoteViews(context.packageName, R.layout.widget_rounded)
                    if (counterToDisplay != null) {
                        bindSingleItem(views, counterToDisplay)
                    }
                    appWidgetManager.updateAppWidget(widgetId, views)
                } else if (this@CounterWidgetProvider is CounterWidgetProviderLock) {
                    val lockViews = RemoteViews(context.packageName, R.layout.widget_lock)
                    if (counterToDisplay != null) {
                        val startedAt = counterToDisplay.getLong("started_at")
                        val period = counterToDisplay.optString("period", "days")
                        val (value, _) = getElapsedValueAndUnit(startedAt, period)
                        val unitAbbr = when (period) {
                            "hours" -> "h"
                            "weeks" -> "w"
                            "months" -> "m"
                            "years" -> "y"
                            else -> "d"
                        }
                        lockViews.setTextViewText(R.id.tv_count, value.toString())
                        lockViews.setTextViewText(R.id.tv_unit, unitAbbr)
                    }
                    appWidgetManager.updateAppWidget(widgetId, lockViews)
                } else {
                    val views = RemoteViews(context.packageName, R.layout.widget_small)
                    if (counterToDisplay != null) {
                        bindSingleItem(views, counterToDisplay)
                    } else {
                        views.setTextViewText(R.id.tv_title, "No Counters")
                        views.setTextViewText(R.id.tv_count, "-")
                    }
                    appWidgetManager.updateAppWidget(widgetId, views)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun getElapsedValueAndUnit(startedAt: Long, period: String): Pair<Long, String> {
        val diff = System.currentTimeMillis() - startedAt
        if (diff <= 0) {
            val unit = when (period) {
                "hours" -> "Hour"
                "weeks" -> "Week"
                "months" -> "Month"
                "years" -> "Year"
                else -> "Day"
            }
            return Pair(0L, unit)
        }
        val value: Long
        val unit: String
        when (period) {
            "hours" -> {
                value = diff / 3600000L
                unit = if (value == 1L) "Hour" else "Hours"
            }
            "weeks" -> {
                value = diff / (86400000L * 7L)
                unit = if (value == 1L) "Week" else "Weeks"
            }
            "months" -> {
                value = (diff / (86400000L * 30.44)).toLong()
                unit = if (value == 1L) "Month" else "Months"
            }
            "years" -> {
                value = (diff / (86400000L * 365.25)).toLong()
                unit = if (value == 1L) "Year" else "Years"
            }
            "days" -> {
                value = diff / 86400000L
                unit = if (value == 1L) "Day" else "Days"
            }
            else -> {
                value = diff / 86400000L
                unit = if (value == 1L) "Day" else "Days"
            }
        }
        return Pair(value, unit)
    }
    
    private fun bindSingleItem(views: RemoteViews, obj: JSONObject) {
        val title = obj.getString("title")
        val startedAt = obj.getLong("started_at")
        val period = obj.optString("period", "days")
        val (value, unit) = getElapsedValueAndUnit(startedAt, period)
        
        views.setTextViewText(R.id.tv_title, title)
        views.setTextViewText(R.id.tv_count, value.toString())
        views.setTextViewText(R.id.tv_unit, unit)
    }

    private fun bindItem(views: RemoteViews, array: JSONArray, index: Int, containerId: Int, titleId: Int, countId: Int, unitId: Int) {
        val obj = array.getJSONObject(index)
        val title = obj.getString("title")
        val startedAt = obj.getLong("started_at")
        val period = obj.optString("period", "days")
        val (value, unit) = getElapsedValueAndUnit(startedAt, period)
        
        views.setViewVisibility(containerId, android.view.View.VISIBLE)
        views.setTextViewText(titleId, title)
        views.setTextViewText(countId, value.toString())
        views.setTextViewText(unitId, unit)
    }
}

class CounterWidgetProviderMedium : CounterWidgetProvider()
class CounterWidgetProviderRounded : CounterWidgetProvider()
class CounterWidgetProviderLock : CounterWidgetProvider()
