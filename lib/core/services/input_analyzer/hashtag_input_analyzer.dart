import 'package:smartplanner/models/enum.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smartplanner/core/services/openai/openai_prompt_helper.dart';
import 'package:smartplanner/core/services/openai/openai_response_parser.dart';
import 'package:smartplanner/core/services/openai/openai_service.dart';

/// 分析單一 hashtag 的文字，推論其語意分類
class HashtagInputAnalyzer {
  static Future<HashtagCategory> analyzeCategory(String text) async {
    try {
      final prompt = OpenAiPromptHelper.buildHashtagCategoryPrompt(text);
      final response = await OpenAiService.sendPrompt(prompt: prompt);

      if (response == null) {
        throw Exception('GPT 回傳為空');
      }

      final category = OpenAiResponseParser.parseHashtagCategory(response);
      return category;
    } catch (e) {
      print('❌ GPT 標籤分類失敗：$e');
      Fluttertoast.showToast(msg: "AI 無法辨識分類，改用內建規則", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
      return ruleAnalyzeCategory(text);
    }
  }

  /// 分析語意分類（名詞、動詞、形容詞等）
  static HashtagCategory ruleAnalyzeCategory(String text) {
    final lower = text.toLowerCase();

    // Rule-based 簡易斷詞分類（可擴充）
    // 1. 動詞：運動、購買、寫、掃、打掃、學、準備、買
    if (_verbKeywords.any((k) => lower.contains(k))) return HashtagCategory.verb;
    // 2. 名詞：健身房、早餐機、手機、課程、文件、電腦
    if (_nounKeywords.any((k) => lower.contains(k))) return HashtagCategory.noun;
    // 3. 形容詞：重要、快速、簡單、困難
    if (_adjKeywords.any((k) => lower.contains(k))) return HashtagCategory.adjective;
    // 4. 主詞：我、媽媽、爸、老師
    if (_subjectKeywords.any((k) => lower.contains(k))) return HashtagCategory.subject;
    // 5. 受詞：禮物、報告、作業、文件
    if (_objectKeywords.any((k) => lower.contains(k))) return HashtagCategory.object;

    return HashtagCategory.unknown;
  }

  static const List<String> _verbKeywords = ['運動', '購買', '寫', '掃', '打掃', '學', '準備', '買'];

  static const List<String> _nounKeywords = ['健身房', '早餐機', '手機', '課程', '文件', '電腦'];

  static const List<String> _adjKeywords = ['重要', '快速', '簡單', '困難'];

  static const List<String> _subjectKeywords = ['我', '媽媽', '爸', '老師'];

  static const List<String> _objectKeywords = ['禮物', '報告', '作業', '文件'];
}
