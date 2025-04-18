# ✅ 保留 SharedPreferences 功能與 GSON 泛型反序列化
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken

# ✅ 保留 Play Core 類別（Flutter deferred components 相關）
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# ✅ Flutter 基本保留設定（Flutter SDK 與 Plugins）
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }

# ✅ App 自訂類別（SmartPlanner 專案中的類別）
-keep class com.example.smartplanner.** { *; }

# ✅ GSON 需要的屬性與註解保留
-keepattributes *Annotation*
-keep class com.example.smartplanner.MemoItem { *; }
-keep class com.example.smartplanner.MemoType { *; }
-keep class com.example.smartplanner.TimeRangeType { *; }


