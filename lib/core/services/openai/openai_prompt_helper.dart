/*
buildMemoAnalysisPrompt(String input)	建立分析「備註／待辦」的 prompt
buildHashtagCategoryPrompt(String word)	建立分析 hashtag 語意分類的 prompt（單字分類）
 */

class OpenAiPromptHelper {
  /// 建立分析 Memo 用的提示詞，使用 Assistant對應的Prompt
  static String buildMemoAnalysisPrompt(String input, DateTime selectedDate) {
    final prompt = '''
      analyze memo
      input: $input
      date: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}
      ''';

    return prompt;
  }

  /// 建立 hashtag 單字語意分類提示詞，使用 Assistant對應的Prompt
  static String buildHashtagCategoryPrompt(String word) {
    final prompt = '''
      analyze category
      word: $word
      ''';
    return prompt;
  }

  //**** 以下為原先的Prompt，紀錄備用 ****/
  // /// 建立分析 Memo 用的提示詞
  // static String buildMemoAnalysisPrompt(String input, DateTime selectedDate) {
  //   final selectedDateStr = "${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日";

  //   return '''
  //       請分析下列句子的語意結構，回傳一段 JSON 格式，內容需符合以下定義：

  //       - type：請根據內容判斷是「備註（note）」或「待辦（todo）」
  //         - note：用來記錄想法、感想、觀察、提醒，並**不一定需要執行**，例如「很有趣」、「記一下」、「將來可能用得到」
  //         - todo：代表需要執行的具體行動，包含明確的目標、計畫或任務，例如「明天去健身房」、「買早餐機」

  //       範例：
  //         - 「吉卜力風格轉換很有趣，晚點測試看看」 → 是 note（因為只是表達興趣）
  //         - 「今天下午要測試吉卜力風格轉換」 → 是 todo（因為有明確計畫）

  //       - timeRangeType：請依據句子中的時間詞語，分類為下列之一：
  //         - "morning"：上午（06:00 ~ 11:59）
  //         - "afternoon"：下午（12:00 ~ 17:59）
  //         - "evening"：晚上（18:00 ~ 23:59）
  //         - "midnight"：凌晨（00:00 ~ 05:59）
  //         - "allDay"：若內容涵蓋多個時間段（例如「從早上玩到下午」）
  //         - "none"：若句子未提及任何具體時間

  //       - targetTime：當 type 為 "todo" 時，請儘可能推論具體時間（格式為 yyyy-MM-dd HH:mm:ss），並依據語意中的時間詞換算為實際時間。
  //         - 若句子中僅提及模糊時間（如「下午」），請根據 timeRangeType 對應下列預設時間：
  //           - "morning" → 06:00
  //           - "afternoon" → 12:00
  //           - "evening" → 18:00
  //           - "midnight" → 00:00
  //           - "allDay" → 06:00
  //           - "none" → null
  //         - 若 type 為 "note"，請將 targetTime 設為 null。

  //       - hashtags：請擷取句子中的主要語意詞（如動作、地點、對象等），每個詞彙應為有語意意義的詞，例如「健身房」「運動」「媽媽」。
  //         - 請排除時間、數字、虛詞與停用詞。
  //         - 限制最多 5 個。

  //       ⚠ 時間詞解析說明：
  //       請將「今天」、「明天」、「後天」等詞，視為相對於當日的具體日期。
  //       👉 今天是：$selectedDateStr

  //       請不要加上 ```json 或其他格式標記，僅輸出純 JSON 結果，例如：

  //       {
  //         "type": "todo",
  //         "timeRangeType": "afternoon",
  //         "targetTime": "2025-04-15 14:00:00",
  //         "hashtags": ["健身房", "運動"]
  //       }

  //       輸入句子如下：
  //       $input
  //       ''';
  // }

  // /// 建立 hashtag 單字語意分類提示詞
  // static String buildHashtagCategoryPrompt(String word) {
  //   return '''
  //     請判斷以下單字的語意類別，請從下列類別中擇一，並僅回傳 JSON：
  //     - "noun": 名詞，例如：健身房、早餐機
  //     - "verb": 動詞，例如：運動、購買
  //     - "adjective": 形容詞，例如：重要、快速
  //     - "subject": 主詞，例如：我、媽媽
  //     - "object": 受詞，例如：文件、禮物
  //     - "unknown": 無法分類或意義模糊

  //     請不要加上 ```json 或任何格式標記，僅輸出純 JSON。
  //     請僅回傳如下格式：
  //     {"category": "noun"}

  //     單字如下：
  //     $word
  //     ''';
  // }
}
