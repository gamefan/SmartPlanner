import 'package:android_intent_plus/android_intent.dart';
import 'package:smartplanner/core/services/notification_service.dart';
import 'package:smartplanner/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:smartplanner/models/enum.dart';
import 'dart:io';

/// 請求通知權限
Future<void> openExactAlarmSettings() async {
  if (Platform.isAndroid) {
    const intent = AndroidIntent(action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM');
    await intent.launch();
  }
}

final _uuid = Uuid();

/// 產生唯一 ID 字串
String generateId() {
  return _uuid.v4();
}

/// 根據 DateTime 時間自動分類對應的時段類型
TimeRangeType getTimeRangeTypeFromDateTime(DateTime time) {
  final hour = time.hour;

  if (hour >= 6 && hour <= 11) {
    return TimeRangeType.morning;
  } else if (hour >= 12 && hour <= 17) {
    return TimeRangeType.afternoon;
  } else if (hour >= 18 && hour <= 23) {
    return TimeRangeType.evening;
  } else {
    return TimeRangeType.midnight; // 0 - 5
  }
}

/// 取得當前時間的時段類型
extension TimeRangeTypeExtension on TimeRangeType {
  static TimeRangeType fromHour(int hour) {
    if (hour >= 6 && hour < 12) return TimeRangeType.morning;
    if (hour >= 12 && hour < 18) return TimeRangeType.afternoon;
    if (hour >= 18 && hour < 24) return TimeRangeType.evening;
    if (hour >= 0 && hour < 6) return TimeRangeType.midnight;
    return TimeRangeType.none;
  }
}

/// extension 根據 DateTime 時間自動分類對應的時段類型（針對 MemoItem 的時間區段）
extension CombineWithTimeRange on DateTime {
  /// 根據 TimeRangeType 將日期與時間區段組合成具體時間
  DateTime? toTargetTime(TimeRangeType range) {
    switch (range) {
      case TimeRangeType.morning:
        return DateTime(year, month, day, 6); // 06:00
      case TimeRangeType.afternoon:
        return DateTime(year, month, day, 12); // 12:00
      case TimeRangeType.evening:
        return DateTime(year, month, day, 18); // 18:00
      case TimeRangeType.midnight:
        return DateTime(year, month, day, 0); // 00:00
      case TimeRangeType.allDay:
        return DateTime(year, month, day, 6); // 同樣給 06:00 開始
      case TimeRangeType.none:
      default:
        return null;
    }
  }

  /// 判斷是否為同一天
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// 根據內容與目標時間建立通知時間與 ID，並處理舊通知刪除
Future<(DateTime?, int?)> buildNotification(String content, DateTime? targetTime, {int? previousNotificationId}) async {
  // 若不需要通知，直接取消原有通知（如 NOTE）
  if (targetTime == null || targetTime.isBefore(DateTime.now())) {
    if (previousNotificationId != null) {
      await NotificationService.cancelNotification(previousNotificationId);
    }
    return (null, null);
  }

  final storage = StorageService();
  final earliest = await storage.loadEarliestHour() ?? 8;
  final latest = await storage.loadLatestHour() ?? 22;
  final behavior = await storage.loadOutOfRangeBehavior() ?? 'skip';

  DateTime? notificationTime;
  final hour = targetTime.hour;

  if (hour < earliest && behavior == 'adjust') {
    notificationTime = DateTime(targetTime.year, targetTime.month, targetTime.day, earliest);
  } else if (hour > latest && behavior == 'adjust') {
    notificationTime = DateTime(targetTime.year, targetTime.month, targetTime.day, latest);
  } else if (hour < earliest || hour > latest) {
    notificationTime = null; // skip 建立
  } else {
    notificationTime = targetTime;
  }

  if (notificationTime == null) {
    if (previousNotificationId != null) {
      await NotificationService.cancelNotification(previousNotificationId);
    }
    return (null, null);
  }

  // 避免 ID 重複
  final pending = await NotificationService.getPendingNotifications();
  final usedIds = pending.map((p) => p.id).toSet();
  int newId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
  while (usedIds.contains(newId)) {
    newId = (newId + 1) % 1000000;
  }

  // 若有舊通知先取消
  if (previousNotificationId != null) {
    await NotificationService.cancelNotification(previousNotificationId);
  }

  await NotificationService.scheduleNotification(
    id: newId,
    title: '待辦提醒',
    body: content,
    scheduledTime: notificationTime,
  );

  return (notificationTime, newId);
}
