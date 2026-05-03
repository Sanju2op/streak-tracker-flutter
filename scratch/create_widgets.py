import os

base_dir = "d:/Dev/streak-tracker/android/app/src/main"
layout_dir = os.path.join(base_dir, "res/layout")
xml_dir = os.path.join(base_dir, "res/xml")
drawable_dir = os.path.join(base_dir, "res/drawable")
kotlin_dir = os.path.join(base_dir, "kotlin/com/sanju2op/streak_tracker")

os.makedirs(layout_dir, exist_ok=True)
os.makedirs(xml_dir, exist_ok=True)
os.makedirs(drawable_dir, exist_ok=True)
os.makedirs(kotlin_dir, exist_ok=True)

# 1. Drawables
with open(os.path.join(drawable_dir, "widget_bg.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#007AFF"/>
    <corners android:radius="16dp"/>
</shape>
""")

with open(os.path.join(drawable_dir, "widget_bg_dark.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#1C1C1E"/>
    <corners android:radius="16dp"/>
</shape>
""")

with open(os.path.join(drawable_dir, "widget_lock_bg.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">
    <solid android:color="#33000000"/>
</shape>
""")

# 2. Layouts
with open(os.path.join(layout_dir, "widget_small.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@drawable/widget_bg"
    android:padding="16dp"
    android:gravity="center_vertical"
    android:id="@+id/widget_root">

    <TextView
        android:id="@+id/tv_title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Counter Name"
        android:textColor="#FFFFFF"
        android:textSize="14sp"
        android:textStyle="bold"
        android:maxLines="1"
        android:ellipsize="end" />

    <TextView
        android:id="@+id/tv_count"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="0"
        android:textColor="#FFFFFF"
        android:textSize="32sp"
        android:textStyle="bold"
        android:layout_marginTop="4dp"/>

    <TextView
        android:id="@+id/tv_unit"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Days"
        android:textColor="#FFFFFF"
        android:textSize="12sp" />
</LinearLayout>
""")

with open(os.path.join(layout_dir, "widget_medium.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="horizontal"
    android:background="@drawable/widget_bg_dark"
    android:padding="12dp"
    android:baselineAligned="false"
    android:id="@+id/widget_root">

    <LinearLayout
        android:id="@+id/item1"
        android:layout_width="0dp"
        android:layout_height="match_parent"
        android:layout_weight="1"
        android:orientation="vertical"
        android:gravity="center"
        android:background="@drawable/widget_bg"
        android:layout_marginEnd="4dp">
        <TextView android:id="@+id/tv_title1" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="12sp" android:textStyle="bold" android:maxLines="1"/>
        <TextView android:id="@+id/tv_count1" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="24sp" android:textStyle="bold"/>
        <TextView android:id="@+id/tv_unit1" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="10sp"/>
    </LinearLayout>

    <LinearLayout
        android:id="@+id/item2"
        android:layout_width="0dp"
        android:layout_height="match_parent"
        android:layout_weight="1"
        android:orientation="vertical"
        android:gravity="center"
        android:background="@drawable/widget_bg"
        android:layout_marginEnd="4dp"
        android:visibility="invisible">
        <TextView android:id="@+id/tv_title2" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="12sp" android:textStyle="bold" android:maxLines="1"/>
        <TextView android:id="@+id/tv_count2" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="24sp" android:textStyle="bold"/>
        <TextView android:id="@+id/tv_unit2" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="10sp"/>
    </LinearLayout>

    <LinearLayout
        android:id="@+id/item3"
        android:layout_width="0dp"
        android:layout_height="match_parent"
        android:layout_weight="1"
        android:orientation="vertical"
        android:gravity="center"
        android:background="@drawable/widget_bg"
        android:visibility="invisible">
        <TextView android:id="@+id/tv_title3" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="12sp" android:textStyle="bold" android:maxLines="1"/>
        <TextView android:id="@+id/tv_count3" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="24sp" android:textStyle="bold"/>
        <TextView android:id="@+id/tv_unit3" android:layout_width="wrap_content" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="10sp"/>
    </LinearLayout>
</LinearLayout>
""")

with open(os.path.join(layout_dir, "widget_lock.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@drawable/widget_lock_bg"
    android:gravity="center"
    android:id="@+id/widget_root">

    <TextView
        android:id="@+id/tv_count"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="0"
        android:textColor="#FFFFFF"
        android:textSize="16sp"
        android:textStyle="bold" />

    <TextView
        android:id="@+id/tv_unit"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="d"
        android:textColor="#CCCCCC"
        android:textSize="10sp" />
</LinearLayout>
""")

# 3. Widget Info XMLs
with open(os.path.join(xml_dir, "widget_small_info.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="110dp"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:updatePeriodMillis="86400000"
    android:initialLayout="@layout/widget_small"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
""")

with open(os.path.join(xml_dir, "widget_medium_info.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:targetCellWidth="4"
    android:targetCellHeight="2"
    android:updatePeriodMillis="86400000"
    android:initialLayout="@layout/widget_medium"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
""")

with open(os.path.join(xml_dir, "widget_lock_info.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="40dp"
    android:minHeight="40dp"
    android:updatePeriodMillis="86400000"
    android:initialLayout="@layout/widget_lock"
    android:resizeMode="none"
    android:widgetCategory="keyguard|home_screen" />
""")

# 4. Kotlin Code
kotlin_code = """package com.sanju2op.streak_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class CounterWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val countersJson = widgetData.getString("counters_json", "[]")
        
        try {
            val array = JSONArray(countersJson)
            
            // For each widget instance
            appWidgetIds.forEach { widgetId ->
                val options = appWidgetManager.getAppWidgetOptions(widgetId)
                val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
                
                if (minWidth > 200) {
                    // Medium Widget (4x2)
                    val views = RemoteViews(context.packageName, R.layout.widget_medium)
                    
                    if (array.length() > 0) {
                        bindItem(views, array, 0, R.id.item1, R.id.tv_title1, R.id.tv_count1, R.id.tv_unit1)
                    }
                    if (array.length() > 1) {
                        bindItem(views, array, 1, R.id.item2, R.id.tv_title2, R.id.tv_count2, R.id.tv_unit2)
                    }
                    if (array.length() > 2) {
                        bindItem(views, array, 2, R.id.item3, R.id.tv_title3, R.id.tv_count3, R.id.tv_unit3)
                    }
                    appWidgetManager.updateAppWidget(widgetId, views)
                } else if (minWidth < 100) {
                    // Lock screen widget
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
                    // Small widget (2x2)
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
"""

with open(os.path.join(kotlin_dir, "CounterWidgetProvider.kt"), "w") as f:
    f.write(kotlin_code)
