/*
parseMemoAnalysis(String jsonText)	AnalyzedMemoResult?	將 GPT 回傳的 JSON 字串轉成 AnalyzedMemoResult 物件
parseHashtagCategory(String jsonText)	HashtagCategory	將 GPT 回傳的 JSON 字串轉成對應的 enum
 */

import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smartplanner/core/services/input_analyzer/memo_input_analyzer.dart';
import 'package:smartplanner/models/enum.dart';

class OpenAiResponseParser {
  /// 解析 GPT 回傳的 Memo 分析 JSON 字串
  static AnalyzedMemoResult? parseMemoAnalysis(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText);
      final typeString = decoded['type'] as String?;
      final timeString = decoded['timeRangeType'] as String?;
      final rawTags = decoded['hashtags'] as List?;
      final hashtags = rawTags?.map((e) => _tryRecoverUtf8(e.toString())).toList() ?? [];

      final type = _parseMemoType(typeString);
      final time = _parseTimeRangeType(timeString);

      return AnalyzedMemoResult(type: type, timeRangeType: time, hashtags: hashtags);
    } catch (e) {
      print('❌ GPT 回傳 JSON 解析失敗：$e');
      Fluttertoast.showToast(
        msg: '❌ GPT 回傳 JSON 解析失敗：$e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return null;
    }
  }

  /// 解析 GPT 回傳的 Hashtag 類別分類 JSON
  static HashtagCategory parseHashtagCategory(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText);
      final categoryStr = decoded['category'] as String?;

      return _parseHashtagCategory(categoryStr);
    } catch (e) {
      print('❌ GPT 回傳 JSON 解析失敗（Hashtag）：$e');
      Fluttertoast.showToast(
        msg: '❌ GPT 回傳 JSON 解析失敗（Hashtag）：$e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return HashtagCategory.unknown;
    }
  }

  /// Enum 解析輔助方法
  static MemoType _parseMemoType(String? value) {
    switch (value) {
      case 'todo':
        return MemoType.todo;
      case 'note':
      default:
        return MemoType.note;
    }
  }

  static TimeRangeType _parseTimeRangeType(String? value) {
    switch (value) {
      case 'morning':
        return TimeRangeType.morning;
      case 'afternoon':
        return TimeRangeType.afternoon;
      case 'evening':
        return TimeRangeType.evening;
      case 'midnight':
        return TimeRangeType.midnight;
      case 'allDay':
        return TimeRangeType.allDay;
      case 'none':
      default:
        return TimeRangeType.none;
    }
  }

  static HashtagCategory _parseHashtagCategory(String? value) {
    switch (value) {
      case 'noun':
        return HashtagCategory.noun;
      case 'verb':
        return HashtagCategory.verb;
      case 'adjective':
        return HashtagCategory.adjective;
      case 'subject':
        return HashtagCategory.subject;
      case 'object':
        return HashtagCategory.object;
      case 'unknown':
      default:
        return HashtagCategory.unknown;
    }
  }

  static String _safeDecodeText(String raw) {
    try {
      // 如果是 \uXXXX 這類轉義字，先包成 JSON 字串再解析一次
      return json.decode('"$raw"');
    } catch (_) {
      return raw;
    }
  }

  static String _tryRecoverUtf8(String text) {
    try {
      // 有些文字會被 escape 掉變成 latin1，這邊嘗試修復
      final bytes = text.codeUnits;
      return utf8.decode(bytes);
    } catch (_) {
      return text;
    }
  }
}
