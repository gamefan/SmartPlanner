import 'package:smartplanner/models/enum.dart';

/// 分析單一 hashtag 的文字，推論其語意分類
class HashtagInputAnalyzer {
  static Future<HashtagCategory> analyzeCategory(String text) async {
    return ruleAnalyzeCategory(text); // 未來換 GPT 分類
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
