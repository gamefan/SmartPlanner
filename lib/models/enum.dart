/// Memo 的資料類型列舉
enum MemoType {
  /// 備註（可無時間 / 無完成狀態）
  /// 每日新增會帶入當日時間，通用新增則不會有時間
  note,

  /// 待辦（可具時間 / 完成狀態）
  todo,
}

/// 預設時間分段類型列舉（供未來統計與篩選用）
enum TimeRangeType {
  /// 未指定時段
  none,

  /// 全日 (使用者特別指定或是跨上午跟下午就當全日)
  allDay,

  /// 上午（6:00 - 11:59）
  morning,

  /// 下午（12:00 - 17:59）
  afternoon,

  /// 晚上（18:00 - 23:59）
  evening,

  /// 凌晨（00:00 - 5:59）
  midnight,
}

/// 語音輸入狀態列舉
enum SpeechStatus {
  /// 無操作
  idle,

  /// 錄音中
  listening,

  /// 辨識中
  processing,

  /// 出錯
  error,
}

/// 標籤的來源類型
enum HashtagSource {
  /// 使用者手動新增
  manual,

  /// AI 自動解析產生
  aiGenerated,
}

/// 標籤的語意分類
enum HashtagCategory {
  /// 名詞（例如：早餐機、健身房）
  noun,

  /// 動詞（例如：購買、運動）
  verb,

  /// 形容詞（例如：重要、快速）
  adjective,

  /// 主詞（例如：我、媽媽）
  subject,

  /// 受詞（例如：文件、禮物）
  object,

  /// 其他無法分類的
  unknown,
}
