//小工具的主入口（繼承 AppWidgetProvider），負責在 updateWidget() 被觸發時連動 UI 資料更新。

/*
onUpdate() 是由系統或 updateWidget() 觸發的進入點。
它會註冊一個 RemoteViewsService 作為資料來源（類似 ListView Adapter）。
data = Uri.parse(...) 是讓每次更新都帶不同 URI，避免舊資料 cache。
setRemoteAdapter(...) 就是把 ListView 內容綁定到你的 MemoWidgetFactory。
 */

package com.example.smartplanner

import android.app.PendingIntent
import android.net.Uri
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.example.smartplanner.MemoType
import com.example.smartplanner.MemoItem


class SmartPlannerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d("SmartPlannerWidget", "onUpdate triggered")

        for (appWidgetId in appWidgetIds) {
            // 綁定資料來源（RemoteViewsService）
            val intent = Intent(context, MemoWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse("content://smartplanner.widget.${appWidgetId}") // 確保唯一
            }

            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                setRemoteAdapter(R.id.memo_list_view, intent)
                setEmptyView(R.id.memo_list_view, R.id.empty_view)

                // ⭐️⭐️⭐️ 關鍵：設定 pending intent template ⭐️⭐️⭐️
                val clickIntent = Intent(context, SmartPlannerWidgetProvider::class.java).apply {
                    action = "ACTION_TOGGLE_MEMO"
                }

                val clickPendingIntent = PendingIntent.getBroadcast(
                    context,
                    0,
                    clickIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setPendingIntentTemplate(R.id.memo_list_view, clickPendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        // 通知更新資料
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.memo_list_view)
    }


    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        Log.d("SmartPlannerWidget", "onReceive called with action: ${intent.action}")

        if (intent.action == "ACTION_TOGGLE_MEMO") {
            val memoId = intent.getStringExtra("memo_id")
            Log.d("SmartPlannerWidget", "ACTION_TOGGLE_MEMO received, memoId: $memoId")

            if (memoId == null) {
                Log.w("SmartPlannerWidget", "No memo_id found in intent")
                return
            }

            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val json = prefs.getString("flutter.memo_items", "[]") ?: "[]"

            Log.d("SmartPlannerWidget", "Loaded memo JSON: $json")

            try {
                val gson = Gson()
                val listType = object : TypeToken<MutableList<MemoItem>>() {}.type
                val memoList: MutableList<MemoItem> = gson.fromJson(json, listType)

                val index = memoList.indexOfFirst { it.id == memoId }
                Log.d("SmartPlannerWidget", "Found memo index: $index")

                if (index != -1) {
                    val memo = memoList[index]
                    Log.d("SmartPlannerWidget", "Memo found: $memo")

                    if (memo.type == MemoType.TODO && memo.isCompleted != null) {
                        val newStatus = !memo.isCompleted
                        memoList[index] = memo.copy(isCompleted = newStatus)
                        prefs.edit().putString("flutter.memo_items", gson.toJson(memoList)).apply()
                        Log.d("SmartPlannerWidget", "Memo updated: isCompleted = $newStatus")
                    } else {
                        Log.w("SmartPlannerWidget", "Memo type is not TODO or isCompleted is null")
                    }
                } else {
                    Log.w("SmartPlannerWidget", "Memo ID not found in list")
                }

                val appWidgetManager = AppWidgetManager.getInstance(context)
                val component = ComponentName(context, SmartPlannerWidgetProvider::class.java)
                appWidgetManager.notifyAppWidgetViewDataChanged(
                    appWidgetManager.getAppWidgetIds(component),
                    R.id.memo_list_view
                )
                Log.d("SmartPlannerWidget", "Widget notified for data changed")
            } catch (e: Exception) {
                Log.e("SmartPlannerWidget", "Error updating memo: ${e.message}", e)
            }
        }
    }

}
