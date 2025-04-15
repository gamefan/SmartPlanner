import 'package:smartplanner/models/enum.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smartplanner/core/services/openai/openai_prompt_helper.dart';
import 'package:smartplanner/core/services/openai/openai_response_parser.dart';
import 'package:smartplanner/core/services/openai/openai_service.dart';

/// 分析單一 hashtag 的文字，推論其語意分類
class HashtagInputAnalyzer {
  /// AI 分析hashtag（GPT 回傳）
  static Future<HashtagCategory> analyzeCategory(String text) async {
    try {
      final prompt = OpenAiPromptHelper.buildHashtagCategoryPrompt(text);

      final runId = await OpenAiService.sendToAssistant(message: prompt);
      if (runId == null) throw Exception('Assistant 建立 Run 失敗');

      final resultText = await OpenAiService.pollRunAndGetResult(runId);
      if (resultText == null) throw Exception('Assistant 回傳為空');

      final category = OpenAiResponseParser.parseHashtagCategory(resultText);
      return category;
    } catch (e) {
      print('❌ Assistant 標籤分類失敗：$e');
      Fluttertoast.showToast(msg: "AI 無法辨識分類，改用內建規則", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
      return ruleAnalyzeCategory(text); // fallback rule-based
    }
  }

  /// 分析語意分類（名詞、動詞、形容詞、主詞、受詞）
  static HashtagCategory ruleAnalyzeCategory(String text) {
    final lower = text.toLowerCase();

    if (_matchAny(lower, _verbKeywords)) return HashtagCategory.verb;
    if (_matchAny(lower, _nounKeywords)) return HashtagCategory.noun;
    if (_matchAny(lower, _adjKeywords)) return HashtagCategory.adjective;
    if (_matchAny(lower, _subjectKeywords)) return HashtagCategory.subject;
    if (_matchAny(lower, _objectKeywords)) return HashtagCategory.object;

    return HashtagCategory.unknown;
  }

  /// 判斷是否符合任何關鍵詞（中文用 contains，英文用完整單字比對）
  static bool _matchAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (_isEnglish(keyword)) {
        // 英文：完整單字比對
        final pattern = RegExp(
          r'(^|[\s,.\!?;:()\[\]{}"“”‘’])' + RegExp.escape(keyword) + r'($|[\s,.\!?;:()\[\]{}"“”‘’])',
          caseSensitive: false,
        );
        if (pattern.hasMatch(text)) return true;
      } else {
        // 中文（含簡體）：使用 contains 判斷
        if (text.contains(keyword)) return true;
      }
    }
    return false;
  }

  /// 判斷是否為英文（簡單判斷）
  static bool _isEnglish(String word) {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(word);
  }

  // 以下為關鍵字清單（含中英繁簡）

  static const List<String> _verbKeywords = [
    '運動',
    '購買',
    '買',
    '寫',
    '掃',
    '打掃',
    '學',
    '學習',
    '準備',
    '整理',
    '打電話',
    '寄',
    '閱讀',
    '訂',
    '報名',
    '修理',
    '运动',
    '购买',
    '学习',
    '打扫',
    '准备',
    '整理',
    '寄',
    '阅读',
    '报名',
    '修理',
    'exercise',
    'buy',
    'write',
    'clean',
    'study',
    'prepare',
    'call',
    'send',
    'read',
    'order',
    'register',
    'fix',
  ];

  static const List<String> _nounKeywords = [
    '健身房',
    '早餐機',
    '手機',
    '課程',
    '文件',
    '電腦',
    '禮物',
    '報告',
    '作業',
    '信件',
    '行程',
    '郵件',
    '會議',
    '車票',
    '門票',
    '健身馆',
    '早餐机',
    '手机',
    '课程',
    '电脑',
    '礼物',
    '报告',
    '作业',
    '邮件',
    '会议',
    'gym',
    'phone',
    'course',
    'document',
    'computer',
    'gift',
    'report',
    'homework',
    'letter',
    'schedule',
    'email',
    'meeting',
    'ticket',
  ];

  static const List<String> _adjKeywords = [
    '重要',
    '快速',
    '簡單',
    '困難',
    '緊急',
    '有趣',
    '無聊',
    '複雜',
    '重要',
    '紧急',
    '简单',
    '困难',
    '有趣',
    '无聊',
    '复杂',
    'important',
    'urgent',
    'simple',
    'easy',
    'hard',
    'fun',
    'boring',
    'complex',
  ];

  static const List<String> _subjectKeywords = [
    '我',
    '媽媽',
    '爸',
    '爸爸',
    '老師',
    '同學',
    '朋友',
    '主管',
    '同事',
    '他',
    '她',
    '我',
    '妈妈',
    '爸爸',
    '老师',
    '同学',
    '同事',
    'i',
    'mom',
    'dad',
    'teacher',
    'classmate',
    'friend',
    'boss',
    'colleague',
    'he',
    'she',
  ];

  static const List<String> _objectKeywords = [
    '禮物',
    '報告',
    '作業',
    '文件',
    '東西',
    '行李',
    '餐點',
    '行程',
    '任務',
    '礼物',
    '报告',
    '作业',
    '文件',
    '东西',
    '行李',
    '餐点',
    '任务',
    'gift',
    'report',
    'homework',
    'document',
    'item',
    'baggage',
    'meal',
    'schedule',
    'task',
  ];
}
