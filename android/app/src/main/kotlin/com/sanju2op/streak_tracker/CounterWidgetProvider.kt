package com.sanju2op.streak_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

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
                if (this@CounterWidgetProvider is CounterWidgetProviderMedium) {
                    val views = RemoteViews(context.packageName, R.layout.widget_medium)
                    if (array.length() > 0) bindItem(views, array, 0, R.id.item1, R.id.tv_title1, R.id.tv_count1, R.id.tv_unit1)
                    if (array.length() > 1) bindItem(views, array, 1, R.id.item2, R.id.tv_title2, R.id.tv_count2, R.id.tv_unit2)
                    if (array.length() > 2) bindItem(views, array, 2, R.id.item3, R.id.tv_title3, R.id.tv_count3, R.id.tv_unit3)
                    appWidgetManager.updateAppWidget(widgetId, views)
                } else if (this@CounterWidgetProvider is CounterWidgetProviderLock) {
                    val views = RemoteViews(context.packageName, R.layout.widget_lock)
                    if (array.length() > 0) {
                        val first = array.getJSONObject(0)
                        val startedAt = first.getLong("started_at")
                        val diff = System.currentTimeMillis() - startedAt
                        val days = diff / 86400000L
                        views.setTextViewText(R.id.tv_count, days.toString())
                    }
                    appWidgetManager.updateAppWidget(widgetId, views)
                } else {
                    val views = RemoteViews(context.packageName, R.layout.widget_small)
                    if (array.length() > 0) {
                        val first = array.getJSONObject(0)
                        val title = first.getString("title")
                        val startedAt = first.getLong("started_at")
                        val diff = System.currentTimeMillis() - startedAt
                        val days = diff / 86400000L
                        
                        views.setTextViewText(R.id.tv_title, title)
                        views.setTextViewText(R.id.tv_count, days.toString())
                        views.setTextViewText(R.id.tv_unit, "Days")
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
class CounterWidgetProviderLock : CounterWidgetProvider()
