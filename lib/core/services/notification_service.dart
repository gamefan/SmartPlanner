import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// 初始化通知（在 main.dart 的 main() 中呼叫一次）
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📩 點擊通知：${response.payload}');
      },
    );

    // ✅ 初始化 Android 通知頻道（這是關鍵！）
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'smart_planner_channel', // 與通知中使用的 channel id 必須一致
      'Smart Planner 提醒',
      description: '用於 Smart Planner 的本地提醒通知',
      importance: Importance.max,
    );

    final androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    // 初始化時區
    tz.initializeTimeZones();

    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  /// 建立一筆通知
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_planner_channel',
          'Smart Planner 提醒',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'todo', // 可選，如果你有點擊通知後的邏輯可以用
      matchDateTimeComponents: null, // 單次提醒，不重複
    );
    print('⏰ 通知排定成功: ID=$id, 時間=${scheduledTime.toLocal()}');
  }

  /// 立即顯示一筆通知（不延遲，用於測試通知功能）
  static Future<void> showInstantNotification({required int id, required String title, required String body}) async {
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_planner_channel',
          'Smart Planner 提醒',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      payload: 'instant', // 可選 payload
    );

    print('📢 立即通知已送出：ID=$id');
  }

  /// 取消一筆通知
  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// 取消所有通知
  static Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}
