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
  static Future<AnalyzedMemoResult> analyze(String input) async {
    try {
      final prompt = OpenAiPromptHelper.buildMemoAnalysisPrompt(input);
      final response = await OpenAiService.sendPrompt(prompt: prompt);

      if (response == null) {
        throw Exception('GPT 回傳為空');
      }

      final result = OpenAiResponseParser.parseMemoAnalysis(response);

      if (result == null) {
        throw Exception('GPT 回傳格式錯誤');
      }

      return result;
    } catch (e) {
      print('❌ GPT 分析失敗：$e');
      Fluttertoast.showToast(msg: "AI 分析失敗 $e，改用預設規則判斷", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
      // 🔧 複製錯誤訊息到系統剪貼簿
      await Clipboard.setData(ClipboardData(text: e.toString()));
      return ruleAnalyze(input); // fallback
    }
  }

  /// 本地分析規則（供測試使用，或 GPT 備援 fallback）
  static AnalyzedMemoResult ruleAnalyze(String input) {
    final lower = input.toLowerCase();

    final isTodo = _containsAction(lower) && _containsTimeHint(lower);
    final timeType = _parseTimeFromText(lower) ?? TimeRangeType.none;
    final hashtags = _extractKeywords(lower);

    return AnalyzedMemoResult(
      type: isTodo ? MemoType.todo : MemoType.note,
      timeRangeType: timeType,
      hashtags: hashtags,
    );
  }

  /// 是否包含「明顯的動作動詞」
  static bool _containsAction(String text) {
    return _verbKeywords.any((k) => text.contains(k));
  }

  /// 是否包含時間提示詞
  static bool _containsTimeHint(String text) {
    return _timeKeywords.any((k) => text.contains(k));
  }

  /// 分析時間區段
  static TimeRangeType? _parseTimeFromText(String text) {
    if (text.contains('凌晨')) return TimeRangeType.midnight;
    if (text.contains('早上') || text.contains('上午')) return TimeRangeType.morning;
    if (text.contains('下午')) return TimeRangeType.afternoon;
    if (text.contains('晚上') || text.contains('傍晚')) return TimeRangeType.evening;

    // ➕ 額外處理「幾點」數字（如三點、3點）
    final match = RegExp(r'([零一二三四五六七八九十\d]+)點').firstMatch(text);
    if (match != null) {
      final hourText = match.group(1)!;
      final hour = _parseHour(hourText);
      if (hour != null) {
        return getTimeRangeTypeFromDateTime(DateTime(2024, 1, 1, hour));
      }
    }

    return null;
  }

  /// 將中文數字 or 數字字串轉為 int（簡易實作）
  static int? _parseHour(String text) {
    const map = {'零': 0, '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10};

    if (int.tryParse(text) != null) {
      return int.parse(text);
    }

    // 特例：三點 → 3
    if (map.containsKey(text)) {
      return map[text];
    }

    // 處理：十一、十二、十三…
    if (text.length == 2 && map.containsKey(text[0]) && text[1] == '十') {
      return map[text[0]]! * 10;
    }

    // 處理：十三（十 + 三）
    if (text.startsWith('十') && map.containsKey(text[1])) {
      return 10 + map[text[1]]!;
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

  // 關鍵詞定義
  static const List<String> _verbKeywords = ['去', '做', '買', '運動', '掃', '學', '寫', '交', '處理'];
  static const List<String> _timeKeywords = ['早上', '上午', '下午', '晚上', '凌晨'];
  static const List<String> _morningKeywords = ['早上', '上午'];
  static const List<String> _afternoonKeywords = ['下午'];
  static const List<String> _eveningKeywords = ['晚上'];
  static const List<String> _midnightKeywords = ['凌晨'];

  static const List<String> _stopWords = ['我', '要', '去', '的', '了', '一下', '今天', '明天', '看看'];
}

/// 分析結果 model
class AnalyzedMemoResult {
  final MemoType type;
  final TimeRangeType timeRangeType;
  final List<String> hashtags;

  const AnalyzedMemoResult({required this.type, required this.timeRangeType, required this.hashtags});
}
