import 'package:flutter_test/flutter_test.dart';
import 'package:smartplanner/core/services/input_analyzer/hashtag_input_analyzer.dart';
import 'package:smartplanner/core/services/input_analyzer/memo_input_analyzer.dart';
import 'package:smartplanner/models/enum.dart';

void main() {
  group('MemoInputAnalyzer', () {
    test('應正確分析為 TODO + 下午 + hashtags', () {
      final result = MemoInputAnalyzer.ruleAnalyze('下午去健身房，運動三小時', DateTime(2025, 1, 1, 12, 0, 0));

      expect(result.type, MemoType.todo);
      expect(result.timeRangeType, TimeRangeType.afternoon);
      expect(result.hashtags, containsAll(['下午去健身房', '運動三小時']));
    });

    test('無動作與時間提示，應為 NOTE + none', () {
      final result = MemoInputAnalyzer.ruleAnalyze('這週有點累，先休息一下', DateTime(2025, 1, 1, 12, 0, 0));

      expect(result.type, MemoType.note);
      expect(result.timeRangeType, TimeRangeType.none);
      expect(result.hashtags.any((tag) => tag.contains('累')), true);
    });

    test('應正確解析「下午三點開會」的目標時間', () {
      final result = MemoInputAnalyzer.ruleAnalyze('下午三點開會', DateTime(2025, 1, 1));
      expect(result.type, MemoType.todo);
      expect(result.targetTime, DateTime(2025, 1, 1, 15, 0));
    });

    test('應正確解析「晚上十點打電動」的目標時間', () {
      final result = MemoInputAnalyzer.ruleAnalyze('晚上十點打電動', DateTime(2025, 1, 1));
      expect(result.type, MemoType.todo);
      expect(result.targetTime, DateTime(2025, 1, 1, 22, 0));
    });

    test('應正確解析「凌晨兩點要睡覺」的目標時間', () {
      final result = MemoInputAnalyzer.ruleAnalyze('凌晨兩點要睡覺', DateTime(2025, 1, 1));
      expect(result.type, MemoType.todo);
      expect(result.targetTime, DateTime(2025, 1, 1, 2, 0));
    });

    test('應正確解析「早上七點運動」的目標時間', () {
      final result = MemoInputAnalyzer.ruleAnalyze('早上七點運動', DateTime(2025, 1, 1));
      expect(result.type, MemoType.todo);
      expect(result.targetTime, DateTime(2025, 1, 1, 7, 0));
    });

    test('應正確解析「十點半出門」的目標時間', () {
      final result = MemoInputAnalyzer.ruleAnalyze('十點半出門', DateTime(2025, 1, 1));
      expect(result.type, MemoType.todo);
      expect(result.targetTime, DateTime(2025, 1, 1, 10, 30));
    });

    test('應正確解析「今天很累，休息一下」的目標時間', () {
      final result = MemoInputAnalyzer.ruleAnalyze('今天很累，休息一下', DateTime(2025, 1, 1));
      expect(result.type, MemoType.note);
      expect(result.targetTime, isNull);
    });
  });

  group('HashtagInputAnalyzer', () {
    test('應正確分類為動詞', () {
      final result = HashtagInputAnalyzer.ruleAnalyzeCategory('運動');
      expect(result, HashtagCategory.verb);
    });

    test('應正確分類為名詞', () {
      final result = HashtagInputAnalyzer.ruleAnalyzeCategory('健身房');
      expect(result, HashtagCategory.noun);
    });

    test('無法分類時回傳 unknown', () {
      final result = HashtagInputAnalyzer.ruleAnalyzeCategory('吼哩共啥');
      expect(result, HashtagCategory.unknown);
    });
  });
}
