import 'package:smartplanner/models/enum.dart';

// === App新增的資料項目 ===

/// MemoItem 資料類別
class MemoItem {
  /// 資料唯一 ID
  final String id;

  /// 輸入內容
  final String content;

  /// 類型（備註 / 待辦）
  final MemoType type;

  /// 建立時間
  final DateTime createdAt;

  /// 目標時間（null 表示無具體時間）
  final DateTime? targetTime;

  /// 完成狀態（null 表示為備註，非待辦）
  final bool? isCompleted;

  /// 標籤清單
  final List<String> hashtags;

  /// 所屬時間區段分類（預設 none）
  final TimeRangeType timeRangeType;

  /// 建構函式
  MemoItem({
    required this.id,
    required this.content,
    required this.type,
    required this.createdAt,
    this.targetTime,
    this.isCompleted,
    this.hashtags = const [],
    this.timeRangeType = TimeRangeType.none,
  });

  /// 工具函式：是否為全日待辦（type = todo 且 targetTime 為 null）
  bool get isAllDayTodo => type == MemoType.todo && targetTime == null;

  /// 工具函式：是否為有時間的待辦（type = todo 且 targetTime 有值）
  bool get isTimedTodo => type == MemoType.todo && targetTime != null;

  /// 複製函式（支援更新特定欄位）
  MemoItem copyWith({
    String? id,
    String? content,
    MemoType? type,
    DateTime? createdAt,
    DateTime? targetTime,
    bool? isCompleted,
    List<String>? hashtags,
    TimeRangeType? timeRangeType,
  }) {
    return MemoItem(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      targetTime: targetTime ?? this.targetTime,
      isCompleted: isCompleted ?? this.isCompleted,
      hashtags: hashtags ?? this.hashtags,
      timeRangeType: timeRangeType ?? this.timeRangeType,
    );
  }

  /// 將 MemoItem 轉為 JSON 格式（Map）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'targetTime': targetTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'hashtags': hashtags,
      'timeRangeType': timeRangeType.name,
    };
  }

  /// 從 JSON 格式（Map）還原 MemoItem
  factory MemoItem.fromJson(Map<String, dynamic> json) {
    return MemoItem(
      id: json['id'],
      content: json['content'],
      type: MemoType.values.byName(json['type']),
      createdAt: DateTime.parse(json['createdAt']),
      targetTime: json['targetTime'] != null ? DateTime.parse(json['targetTime']) : null,
      isCompleted: json['isCompleted'],
      hashtags: List<String>.from(json['hashtags']),
      timeRangeType: TimeRangeType.values.byName(json['timeRangeType']),
    );
  }
}
