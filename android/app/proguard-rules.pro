# 保留 SharedPreferences 的反射功能，避免 release 模式資料讀不到
-keep class io.flutter.plugins.sharedpreferences.** { *; }