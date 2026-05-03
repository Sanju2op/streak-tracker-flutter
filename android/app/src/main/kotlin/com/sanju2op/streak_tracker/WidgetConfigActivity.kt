package com.sanju2op.streaktracker

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.ListView
import org.json.JSONArray

class WidgetConfigActivity : Activity() {
    private var mAppWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            mAppWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        if (mAppWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val countersJson = prefs.getString("counters_json", "[]") ?: "[]"
        val array = JSONArray(countersJson)
        val titles = mutableListOf<String>()
        val ids = mutableListOf<String>()

        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            titles.add(obj.getString("title"))
            ids.add(obj.getString("id"))
        }

        if (titles.isEmpty()) {
            finish()
            return
        }

        val listView = ListView(this)
        val adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, titles)
        listView.adapter = adapter
        listView.setOnItemClickListener { _, _, position, _ ->
            val selectedId = ids[position]
            val edit = prefs.edit()
            edit.putString("widget_id_$mAppWidgetId", selectedId)
            edit.apply()

            val appWidgetManager = AppWidgetManager.getInstance(this)
            // Trigger an update for this specific widget
            // In a real app, you'd call CounterWidgetProvider.onUpdate here
            
            val resultValue = Intent()
            resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, mAppWidgetId)
            setResult(RESULT_OK, resultValue)
            finish()
        }

        setContentView(listView)
    }
}
