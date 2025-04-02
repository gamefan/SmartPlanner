import 'package:uuid/uuid.dart';
import 'package:smartplanner/models/enum.dart';

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
