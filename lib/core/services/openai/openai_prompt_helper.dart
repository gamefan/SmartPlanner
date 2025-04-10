/*
buildMemoAnalysisPrompt(String input)	建立分析「備註／待辦」的 prompt
buildHashtagCategoryPrompt(String word)	建立分析 hashtag 語意分類的 prompt（單字分類）
 */

class OpenAiPromptHelper {
  /// 建立分析 Memo 用的提示詞
  static String buildMemoAnalysisPrompt(String input) {
    return '''
    請分析下列句子的語意結構，回傳一段 JSON 格式，內容需符合以下定義：

    - type：請根據內容判斷是「備註（note）」或「待辦（todo）」
      - note：用來記錄想法、感想、觀察、提醒，並**不一定需要執行**，例如「很有趣」、「記一下」、「將來可能用得到」
      - todo：代表需要執行的具體行動，包含明確的目標、計畫或任務，例如「明天去健身房」、「買早餐機」
    例子：
      - 「吉卜力風格轉換很有趣，晚點測試看看」 → 是 note（因為只是表達興趣）
      - 「今天下午要測試吉卜力風格轉換」 → 是 todo（因為有明確計畫）
    - timeRangeType：請依據句子時間詞語，分類為下列之一：
      - "morning"：上午（06:00 ~ 11:59）
      - "afternoon"：下午（12:00 ~ 17:59）
      - "evening"：晚上（18:00 ~ 23:59）
      - "midnight"：凌晨（00:00 ~ 05:59）
      - "allDay"：若內容涵蓋多個時間段（例如「從早上玩到下午」）
      - "none"：若句子未提及任何具體時間

    - hashtags：請擷取句子中的主要語意詞（如動作、地點、對象等），每個詞彙應為有語意意義的詞，例如「健身房」「運動」「媽媽」。請排除時間、數字、虛詞與停用詞，並限制最多 5 個。

    請不要加上 ```json 或任何格式標記，僅輸出純 JSON。
    請僅回傳 JSON 結果，例如：

    {
      "type": "todo",
      "timeRangeType": "afternoon",
      "hashtags": ["健身房", "運動"]
    }

    輸入句子如下：
    $input
    ''';
  }

  /// 建立 hashtag 單字語意分類提示詞
  static String buildHashtagCategoryPrompt(String word) {
    return '''
      請判斷以下單字的語意類別，請從下列類別中擇一，並僅回傳 JSON：
      - "noun": 名詞，例如：健身房、早餐機
      - "verb": 動詞，例如：運動、購買
      - "adjective": 形容詞，例如：重要、快速
      - "subject": 主詞，例如：我、媽媽
      - "object": 受詞，例如：文件、禮物
      - "unknown": 無法分類或意義模糊

      請不要加上 ```json 或任何格式標記，僅輸出純 JSON。
      請僅回傳如下格式：
      {"category": "noun"}

      單字如下：
      $word
      ''';
  }
}
