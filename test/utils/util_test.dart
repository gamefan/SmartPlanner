import 'package:flutter_test/flutter_test.dart';
import 'package:smartplanner/core/utils/util.dart';
import 'package:smartplanner/models/enum.dart';

void main() {
  group('getTimeRangeTypeFromDateTime', () {
    test('returns midnight for hours 0 to 5', () {
      expect(getTimeRangeTypeFromDateTime(DateTime(2024, 1, 1, 0)), TimeRangeType.midnight);
      expect(getTimeRangeTypeFromDateTime(DateTime(2024, 1, 1, 5, 59)), TimeRangeType.midnight);
    });

    test('returns morning for hours 6 to 11', () {
      expect(getTimeRangeTypeFromDateTime(DateTime(2024, 1, 1, 6)), TimeRangeType.morning);
      expect(getTimeRangeTypeFromDateTime(DateTime(2024, 1, 1, 11, 59)), TimeRangeType.morning);
    });

    test('returns afternoon for hours 12 to 17', () {
      expect(getTimeRangeTypeFromDateTime(DateTime(2024, 1, 1, 12)), TimeRangeType.afternoon);
      expect(getTimeRangeTypeFromDateTime(DateTime(2024, 1, 1, 17, 59)), TimeRangeType.afternoon);
    });

    test('returns evening for hours 18 to 23', () {
      expect(getTimeRangeTypeFromDateTime(DateTime(2024, 1, 1, 18)), TimeRangeType.evening);
      expect(getTimeRangeTypeFromDateTime(DateTime(2024, 1, 1, 23, 59)), TimeRangeType.evening);
    });
  });
}
