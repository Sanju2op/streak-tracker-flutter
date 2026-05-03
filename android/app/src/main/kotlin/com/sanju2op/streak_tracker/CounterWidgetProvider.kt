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
                        val diff = System.currentTimeMillis() - startedAt
                        val days = diff / 86400000L
                        lockViews.setTextViewText(R.id.tv_count, days.toString())
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
    
    private fun bindSingleItem(views: RemoteViews, obj: JSONObject) {
        val title = obj.getString("title")
        val startedAt = obj.getLong("started_at")
        val diff = System.currentTimeMillis() - startedAt
        val days = diff / 86400000L
        
        views.setTextViewText(R.id.tv_title, title)
        views.setTextViewText(R.id.tv_count, days.toString())
        views.setTextViewText(R.id.tv_unit, "Days")
    }

    private fun bindItem(views: RemoteViews, array: JSONArray, index: Int, containerId: Int, titleId: Int, countId: Int, unitId: Int) {
        val obj = array.getJSONObject(index)
        val title = obj.getString("title")
        val startedAt = obj.getLong("started_at")
        val diff = System.currentTimeMillis() - startedAt
        val days = diff / 86400000L
        
        views.setViewVisibility(containerId, android.view.View.VISIBLE)
        views.setTextViewText(titleId, title)
        views.setTextViewText(countId, days.toString())
        views.setTextViewText(unitId, "Days")
    }
}

class CounterWidgetProviderMedium : CounterWidgetProvider()
class CounterWidgetProviderRounded : CounterWidgetProvider()
class CounterWidgetProviderLock : CounterWidgetProvider()
