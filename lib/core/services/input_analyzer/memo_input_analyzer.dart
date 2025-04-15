import 'package:fluttertoast/fluttertoast.dart';
import 'package:smartplanner/core/utils/util.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/core/services/openai/openai_prompt_helper.dart';
import 'package:smartplanner/core/services/openai/openai_response_parser.dart';
import 'package:smartplanner/core/services/openai/openai_service.dart';
import 'package:flutter/services.dart'; // ✅ 系統剪貼簿功能

/// 分析輸入內容（備註或待辦），預測其類型、時間與關聯 hashtags。
class MemoInputAnalyzer {
  /// 正式用的分析方法（GPT 回傳）
  static Future<AnalyzedMemoResult> analyze(String input, DateTime selectedDate) async {
    try {
      final prompt = OpenAiPromptHelper.buildMemoAnalysisPrompt(input, selectedDate);
      final runId = await OpenAiService.sendToAssistant(message: prompt);
      if (runId == null) throw Exception('Assistant 建立 Run 失敗');

      final resultText = await OpenAiService.pollRunAndGetResult(runId);
      if (resultText == null) throw Exception('Assistant 回傳為空');

      final result = OpenAiResponseParser.parseMemoAnalysis(resultText);
      if (result == null) throw Exception('Assistant 回傳格式錯誤');

      return result;
    } catch (e) {
      print('❌ Assistant 分析失敗：$e');
      Fluttertoast.showToast(msg: "AI 分析失敗 $e，改用預設規則判斷", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
      await Clipboard.setData(ClipboardData(text: e.toString())); // 🔧 可複製錯誤訊息
      return ruleAnalyze(input, selectedDate); // fallback
    }
  }

  /// 本地分析規則（供測試使用，或 GPT 備援 fallback）
  static AnalyzedMemoResult ruleAnalyze(String input, DateTime selectedDate) {
    final lower = input.toLowerCase();

    final timeType = _parseTimeFromText(lower) ?? TimeRangeType.none;
    final hasExplicitTime = _extractExplicitTime(lower, selectedDate, timeType) != null;
    final hasTimeHint = _containsTimeHintText(lower);
    final isTodo = _containsAction(lower) && (hasExplicitTime || hasTimeHint);
    final hashtags = _extractKeywords(lower);

    DateTime? targetTime;

    // ✅ 嘗試解析精確時間
    if (isTodo) {
      targetTime = _extractExplicitTime(lower, selectedDate, timeType);

      // ❌ 若解析不到，才 fallback 為區段預設時間
      targetTime ??= selectedDate.toTargetTime(timeType);
    }

    return AnalyzedMemoResult(
      type: isTodo ? MemoType.todo : MemoType.note,
      timeRangeType: timeType,
      hashtags: hashtags,
      targetTime: isTodo ? targetTime : null,
      adjustedContent: input, // ruleAnalyze不改輸入
    );
  }

  /// 是否包含「明顯的動作動詞」
  static bool _containsAction(String text) {
    return _verbKeywords.any((k) => text.contains(k));
  }

  /// 分析時間區段
  static TimeRangeType? _parseTimeFromText(String text) {
    if (text.contains('凌晨')) return TimeRangeType.midnight;
    if (text.contains('早上') || text.contains('上午')) return TimeRangeType.morning;
    if (text.contains('下午')) return TimeRangeType.afternoon;
    if (text.contains('晚上') || text.contains('傍晚')) return TimeRangeType.evening;

    // ➕ 額外處理「幾點」數字（如三點、3點）
    final match = RegExp(r'([零一二三四五六七八九十壹貳參肆伍陸柒捌玖拾\d]+)點').firstMatch(text);
    if (match != null) {
      final hourText = match.group(1)!;
      final hour = _parseHour(hourText);
      if (hour != null) {
        return getTimeRangeTypeFromDateTime(DateTime(2024, 1, 1, hour));
      }
    }

    return null;
  }

  /// 簡易關鍵字擷取，當作 hashtag 使用（可未來替換成 AI）
  static List<String> _extractKeywords(String text) {
    final result = <String>[];

    final segments = text
        .replaceAll(RegExp(r'[，。,.!?！]'), ' ')
        .split(' ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !_stopWords.contains(s));

    result.addAll(segments);
    return result.toSet().toList();
  }

  static bool _containsTimeHintText(String text) {
    return _timeKeywords.any((k) => text.contains(k));
  }

  /// 嘗試從文字中解析出明確的時間資訊（如「下午3點」「三點半」「AM 04:00」）
  static DateTime? _extractExplicitTime(String text, DateTime selectedDate, TimeRangeType timeHint) {
    final pattern = RegExp(
      r'(凌晨|早上|上午|中午|下午|傍晚|晚上|am|pm)?\s*'
      r'([0-9零一二三四五六七八九十壹貳參肆伍陸柒捌玖拾兩]{1,3})'
      r'(點半|點(?:(?:[0-9零一二三四五六七八九十壹貳參肆伍陸柒捌玖拾]{1,2})分?)?)',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);
    if (match == null) return null;

    final meridiem = match.group(1)?.trim();
    final hourText = match.group(2)?.trim() ?? '';
    final suffix = match.group(3)?.trim();

    final hour = _parseHour(hourText);
    if (hour == null || hour < 0 || hour > 24) return null;

    int minute = 0;

    if (suffix != null) {
      if (suffix.contains('半')) {
        minute = 30;
      } else {
        // 🔍 抓出後綴中真正的分鐘數（可含「分」結尾）
        final minuteMatch = RegExp(r'([0-9零一二三四五六七八九十壹貳參肆伍陸柒捌玖拾]{1,2})分?$').firstMatch(suffix);
        if (minuteMatch != null) {
          final parsed = _parseHour(minuteMatch.group(1)!);
          if (parsed != null && parsed >= 0 && parsed < 60) {
            minute = parsed;
          }
        }
      }
    }

    int resolvedHour = hour;

    // ✅ 時段詞進行 AM/PM 處理
    if (meridiem != null) {
      if (meridiem.contains('下午') || meridiem.contains('晚上') || meridiem.contains('傍晚') || meridiem.contains('pm')) {
        if (resolvedHour < 12) resolvedHour += 12;
      } else if (meridiem.contains('凌晨') && resolvedHour == 12) {
        resolvedHour = 0;
      } else if (meridiem.contains('am') && resolvedHour == 12) {
        resolvedHour = 0;
      } else if (meridiem.contains('中午') && resolvedHour < 11) {
        resolvedHour += 12; // 中午一點 → 13:00
      }
    } else {
      // 若沒有時段詞，根據 timeHint 推論 AM/PM
      if (timeHint == TimeRangeType.afternoon || timeHint == TimeRangeType.evening) {
        if (resolvedHour < 12) resolvedHour += 12;
      }
    }

    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, resolvedHour, minute);
  }

  /// 將中文數字 or 數字字串轉為 int（簡易實作）
  static int? _parseHour(String text) {
    const map = {
      '零': 0,
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
      '十': 10,
      '壹': 1,
      '貳': 2,
      '參': 3,
      '肆': 4,
      '伍': 5,
      '陸': 6,
      '柒': 7,
      '捌': 8,
      '玖': 9,
      '拾': 10,
      '兩': 2,
    };

    if (int.tryParse(text) != null) {
      return int.parse(text);
    }

    if (map.containsKey(text)) return map[text];

    // 十一、十二、二十三…
    if (text.length == 2) {
      if (text.startsWith('十') || text.startsWith('拾')) {
        final unit = map[text[1]] ?? int.tryParse(text[1]);
        return 10 + (unit ?? 0);
      }
      if ((map.containsKey(text[0]) && (text[1] == '十' || text[1] == '拾'))) {
        return map[text[0]]! * 10;
      }
    }

    // 二十三這類
    if (text.length == 3 &&
        map.containsKey(text[0]) &&
        (text[1] == '十' || text[1] == '拾') &&
        map.containsKey(text[2])) {
      return map[text[0]]! * 10 + map[text[2]]!;
    }

    return null;
  }

  // 關鍵詞定義
  static const List<String> _verbKeywords = [
    '買',
    '吃',
    '寫',
    '練',
    '修',
    '刷',
    '跑',
    '洗',
    '讀',
    '看',
    '聽',
    '做',
    '學',
    '玩',
    '出',
    '約',
    '聚',
    '喝',
    '打',
    '運動',
    '開會',
    '出門',
    '上課',
    '學習',
    '健身',
    '考試',
    '上班',
    '打電動',
    '看電影',
    '約會',
    '旅行',
    '聚餐',
    '喝酒',
    '休息',
    '放鬆',
    '學習新技能',
    '閱讀',
    '寫作',
    '做運動',
    '打掃',
    '整理',
    '計畫',
    '設計',
    '創作',
    '拍照',
    '錄影',
    '編輯',
    '分享',
    '討論',
    '交流',
    '參加',
    '睡覺',
  ];
  static const List<String> _timeKeywords = ['早上', '上午', '下午', '晚上', '凌晨', '傍晚', '中午', 'AM', 'PM'];

  static const List<String> _stopWords = [
    '我',
    '你',
    '要',
    '去',
    '的',
    '了',
    '一下',
    '今天',
    '明天',
    '看看',
    '這個',
    '那個',
    '這些',
    '那些',
    '這樣',
    '那樣',
    '這麼',
    '那麼',
    '怎麼',
    '怎樣',
    '什麼',
    '誰',
    '哪裡',
    '為什麼',
    '怎麼樣',
  ];
}

/// 分析結果 model
class AnalyzedMemoResult {
  final MemoType type;
  final TimeRangeType timeRangeType;
  final List<String> hashtags;
  final DateTime? targetTime; // 目標時間（null 表示無具體時間）
  final String adjustedContent; // 語意重寫後的句子內容

  const AnalyzedMemoResult({
    required this.type,
    required this.timeRangeType,
    required this.hashtags,
    this.targetTime,
    required this.adjustedContent,
  });
}
