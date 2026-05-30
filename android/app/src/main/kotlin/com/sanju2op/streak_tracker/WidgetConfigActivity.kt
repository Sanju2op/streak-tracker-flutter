package com.sanju2op.streaktracker

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject

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

        if (array.length() == 0) {
            finish()
            return
        }

        // Determine Theme Mode (Light / Dark)
        val uiMode = resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
        val isDarkMode = uiMode == android.content.res.Configuration.UI_MODE_NIGHT_YES

        val bgColor = if (isDarkMode) 0xFF000000.toInt() else 0xFFF2F2F7.toInt()
        val textPrimaryColor = if (isDarkMode) 0xFFFFFFFF.toInt() else 0xFF000000.toInt()
        val textSecondaryColor = 0xFF8E8E93.toInt()
        val cardColor = if (isDarkMode) 0xFF1C1C1E.toInt() else 0xFFFFFFFF.toInt()

        // Configure Window Style
        window.statusBarColor = bgColor
        if (!isDarkMode) {
            // Dark status bar icons in light mode
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        }

        // Root Layout
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(bgColor)
            val pad = dpToPx(20)
            setPadding(pad, dpToPx(32), pad, pad)
        }

        // Header Title
        val titleView = TextView(this).apply {
            text = "Choose Streak"
            setTextColor(textPrimaryColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 26f)
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
        }
        root.addView(titleView)

        // Header Subtitle
        val subtitleView = TextView(this).apply {
            text = "Select a counter to display on this widget."
            setTextColor(textSecondaryColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setPadding(0, dpToPx(4), 0, dpToPx(24))
        }
        root.addView(subtitleView)

        // Scrollable Area
        val scrollView = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
            isVerticalScrollBarEnabled = false
        }

        val listContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        // Populate Items
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            val title = obj.getString("title")
            val id = obj.getString("id")
            val colorHex = obj.optString("color", "#007AFF")
            val period = obj.optString("period", "days")

            val themeColor = try {
                Color.parseColor(colorHex)
            } catch (e: Exception) {
                0xFF007AFF.toInt()
            }

            // Beautiful rounded card layout for each item
            val itemLayout = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                val pad16 = dpToPx(16)
                setPadding(pad16, pad16, pad16, pad16)
                
                // Rounded corner background
                background = GradientDrawable().apply {
                    setColor(cardColor)
                    cornerRadius = dpToPx(16).toFloat()
                }

                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(0, 0, 0, dpToPx(12))
                }

                isClickable = true
                isFocusable = true
            }

            // Left Color Ring/Dot Indicator
            val colorIndicator = View(this).apply {
                layoutParams = LinearLayout.LayoutParams(dpToPx(16), dpToPx(16)).apply {
                    gravity = Gravity.CENTER_VERTICAL
                }
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(themeColor)
                }
            }
            itemLayout.addView(colorIndicator)

            // Text Info Layout (Vertical)
            val textLayout = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    1f
                ).apply {
                    setMargins(dpToPx(16), 0, 0, 0)
                }
            }

            // Streak Title
            val itemTitle = TextView(this).apply {
                text = title
                setTextColor(textPrimaryColor)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                typeface = Typeface.DEFAULT_BOLD
                maxLines = 1
                ellipsize = android.text.TextUtils.TruncateAt.END
            }
            textLayout.addView(itemTitle)

            // Dynamic Period Subtitle (e.g. "Tracking in Hours")
            val itemSubtitle = TextView(this).apply {
                val capitalizedPeriod = period.replaceFirstChar { it.uppercase() }
                text = "Tracking in $capitalizedPeriod"
                setTextColor(textSecondaryColor)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                setPadding(0, dpToPx(2), 0, 0)
            }
            textLayout.addView(itemSubtitle)

            itemLayout.addView(textLayout)

            // Click Handler
            itemLayout.setOnClickListener {
                val edit = prefs.edit()
                edit.putString("widget_id_$mAppWidgetId", id)
                edit.apply()

                // Trigger immediate, dynamic update for the widget
                val appWidgetManager = AppWidgetManager.getInstance(this@WidgetConfigActivity)
                val info = appWidgetManager.getAppWidgetInfo(mAppWidgetId)
                if (info != null) {
                    val providerClassName = info.provider.className
                    val provider = when (providerClassName) {
                        "com.sanju2op.streaktracker.CounterWidgetProviderMedium" -> CounterWidgetProviderMedium()
                        "com.sanju2op.streaktracker.CounterWidgetProviderRounded" -> CounterWidgetProviderRounded()
                        "com.sanju2op.streaktracker.CounterWidgetProviderLock" -> CounterWidgetProviderLock()
                        else -> CounterWidgetProvider()
                    }
                    provider.onUpdate(
                        this@WidgetConfigActivity,
                        appWidgetManager,
                        intArrayOf(mAppWidgetId),
                        prefs
                    )
                }

                val resultValue = Intent().apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, mAppWidgetId)
                }
                setResult(RESULT_OK, resultValue)
                finish()
            }

            listContainer.addView(itemLayout)
        }

        scrollView.addView(listContainer)
        root.addView(scrollView)
        setContentView(root)
    }

    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            resources.displayMetrics
        ).toInt()
    }
}
