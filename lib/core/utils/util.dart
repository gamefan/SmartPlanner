import 'package:android_intent_plus/android_intent.dart';
import 'package:uuid/uuid.dart';
import 'package:smartplanner/models/enum.dart';

import 'dart:io';
import 'package:flutter/material.dart';

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
}
