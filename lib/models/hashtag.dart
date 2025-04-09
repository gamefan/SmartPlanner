import 'package:smartplanner/core/utils/util.dart';
import 'package:smartplanner/models/enum.dart';

/// Hashtag 資料模型
class Hashtag {
  /// 唯一 ID
  final String id;

  /// 顯示文字
  final String name;

  /// 分類類型
  final HashtagCategory category;

  /// 標籤來源
  final HashtagSource source;

  /// 建立時間
  final DateTime createdAt;

  Hashtag({
    required this.id,
    required this.name,
    this.category = HashtagCategory.unknown,
    this.source = HashtagSource.manual,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 空的 Hashtag 物件
  factory Hashtag.empty() => Hashtag(id: '', name: '', source: HashtagSource.manual, category: HashtagCategory.unknown);

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// 建立新的 Hashtag（簡化版）
  factory Hashtag.simple(String name, {HashtagSource source = HashtagSource.manual}) {
    return Hashtag(id: generateId(), name: name, source: source);
  }

  /// 複製物件
  Hashtag copyWith({String? id, String? name, HashtagCategory? category, HashtagSource? source, DateTime? createdAt}) {
    return Hashtag(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// JSON 序列化
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'source': source.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// JSON 反序列化
  factory Hashtag.fromJson(Map<String, dynamic> json) {
    return Hashtag(
      id: json['id'] as String,
      name: json['name'] as String,
      category: HashtagCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => HashtagCategory.unknown,
      ),
      source: HashtagSource.values.firstWhere((e) => e.name == json['source'], orElse: () => HashtagSource.manual),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
