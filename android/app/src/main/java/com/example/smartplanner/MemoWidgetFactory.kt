// 負責將 SharedPreferences 中的 Memo 資料讀出、過濾今天的項目、產生 RemoteViews 清單給小工具顯示。
/*
SharedPreferences 讀資料    從 flutter.memoList 中取出 JSON 字串
過濾今日資料                 以 targetTime 優先，其次用 createdAt，只保留今天的
顯示                        左邊為 checkbox、右邊為內容文字，完成會加刪除線
                            勾選後會更新UI並回存檔
錯誤處理                    若 JSON 格式錯誤不會閃退（安全處理）
 */

package com.example.smartplanner

import android.app.PendingIntent
import android.os.Bundle
import android.util.Log
import android.content.Context
import android.content.Intent
import android.graphics.Paint
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import com.google.gson.reflect.TypeToken
import java.time.LocalDate
import java.time.format.DateTimeFormatter


enum class MemoType {
    @SerializedName("note") NOTE,
    @SerializedName("todo") TODO
}

enum class TimeRangeType {
    @SerializedName("none") NONE,
    @SerializedName("allDay") ALLDAY,
    @SerializedName("morning") MORNING,
    @SerializedName("afternoon") AFTERNOON,
    @SerializedName("evening") EVENING,
    @SerializedName("midnight") MIDNIGHT
}

data class MemoItem(
    val id: String,
    val content: String,
    val type: MemoType,
    val createdAt: String,
    val targetTime: String? = null,
    val isCompleted: Boolean? = null,
    val hashtags: List<String> = emptyList(),
    val timeRangeType: TimeRangeType = TimeRangeType.NONE,
    val notificationTime: String? = null,
    val notificationId: Int? = null
)

class MemoWidgetFactory(private val context: Context, intent: Intent) : RemoteViewsService.RemoteViewsFactory {

    private var todayMemos: List<MemoItem> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        Log.d("MemoWidgetFactory", "onDataSetChanged 被呼叫")

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("flutter.memo_items", "[]") ?: "[]"

        Log.d("MemoWidgetFactory", "原始 JSON：$json")

        try {
            val gson = Gson()
            val listType = object : TypeToken<List<MemoItem>>() {}.type
            val allMemos: List<MemoItem> = gson.fromJson(json, listType)

            val today = LocalDate.now()
            val formatter = DateTimeFormatter.ISO_DATE_TIME

            todayMemos = allMemos.filter { memo ->
                if (memo.type != MemoType.TODO) return@filter false
                if (memo.content.isBlank()) return@filter false

                val dateStr = memo.targetTime ?: memo.createdAt
                try {
                    val date = LocalDate.parse(dateStr.substring(0, 10))
                    date == today
                } catch (e: Exception) {
                    false
                }
            }
            Log.d("MemoWidgetFactory", "今日符合條件的 TODO 筆數：${todayMemos.size}")
        } catch (e: Exception) {
            todayMemos = emptyList()
        }
    }

    override fun getCount(): Int = todayMemos.size

    override fun getViewAt(position: Int): RemoteViews {
        val memo = todayMemos[position]
        Log.d("MemoWidgetFactory", "getViewAt for ${memo.id} / ${memo.content}")
        val views = RemoteViews(context.packageName, R.layout.widget_list_item)

        views.setTextViewText(R.id.memo_text, memo.content)
        // 因為 RemoteViews 不支援checkbox，所以用 ImageView 來顯示勾選狀態
        val iconRes = if (memo.isCompleted == true) R.drawable.ic_checked else R.drawable.ic_unchecked
            views.setImageViewResource(R.id.memo_checkbox_icon, iconRes)

        if (memo.isCompleted == true) {
            views.setInt(R.id.memo_text, "setPaintFlags", Paint.STRIKE_THRU_TEXT_FLAG)
        } else {
            views.setInt(R.id.memo_text, "setPaintFlags", 0)
        }

        // 加入勾選點擊事件處理
        val fillInIntent = Intent().apply {
            Log.d("MemoWidgetFactory", "填入點擊 Intent 的 memo_id: ${memo.id}")
            putExtra("memo_id", memo.id)
        }
        
        // 綁定item的點擊事件
        views.setOnClickFillInIntent(R.id.memo_item_container, fillInIntent)

        return views
    }


    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
    override fun onDestroy() {
        todayMemos = emptyList()
    }
}
