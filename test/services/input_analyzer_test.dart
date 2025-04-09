import 'package:flutter_test/flutter_test.dart';
import 'package:smartplanner/core/services/input_analyzer/hashtag_input_analyzer.dart';
import 'package:smartplanner/core/services/input_analyzer/memo_input_analyzer.dart';
import 'package:smartplanner/models/enum.dart';

void main() {
  group('MemoInputAnalyzer', () {
    test('應正確分析為 TODO + 下午 + hashtags', () {
      final result = MemoInputAnalyzer.ruleAnalyze('下午去健身房，運動三小時');

      expect(result.type, MemoType.todo);
      expect(result.timeRangeType, TimeRangeType.afternoon);
      expect(result.hashtags, containsAll(['下午去健身房', '運動三小時']));
    });

    test('無動作與時間提示，應為 NOTE + none', () {
      final result = MemoInputAnalyzer.ruleAnalyze('這週有點累，先休息一下');

      expect(result.type, MemoType.note);
      expect(result.timeRangeType, TimeRangeType.none);
      expect(result.hashtags.any((tag) => tag.contains('累')), true);
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
