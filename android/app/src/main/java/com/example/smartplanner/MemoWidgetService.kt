// 提供小工具 ListView 的資料來源工廠 → 連接 MemoWidgetFactory.kt
/*
這個 Service 是小工具用來產出「多列內容」（類似 ListView adapter）的連接橋樑。
他會回傳 MemoWidgetFactory，該檔案負責實際填入每一列的內容。
 */

package com.example.smartplanner

import android.content.Intent
import android.widget.RemoteViewsService

class MemoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return MemoWidgetFactory(applicationContext, intent)
    }
}
