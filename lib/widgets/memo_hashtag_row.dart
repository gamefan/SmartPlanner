import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/providers/hashtag_provider.dart';

/// 顯示 MemoItem 中的 Hashtag 列表（橫向可捲動）
class MemoHashtagRow extends ConsumerWidget {
  final List<String> hashtagIds;

  const MemoHashtagRow({super.key, required this.hashtagIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTags = ref.watch(hashtagProvider);
    final tags = allTags.where((h) => hashtagIds.contains(h.id)).toList();

    if (tags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 30,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              tags.map((tag) {
                final isAi = tag.source == HashtagSource.aiGenerated;
                final bgColor = isAi ? const Color(0xFFCFD8DC) : const Color(0xFFFFF59D);

                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: Material(
                    shape: const _SmallLabelShapeBorder(),
                    color: bgColor,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 4, 10, 4), // 左側多加點空間
                      child: Text(tag.name, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

/// 自定義形狀：圓角矩形 + 銳角弧形
class _SmallLabelShapeBorder extends ShapeBorder {
  const _SmallLabelShapeBorder();

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.only(left: 8); // 左邊留空白避免擠壓

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final radius = 4.0;
    final notchWidth = 10.0;
    final notchHeight = rect.height / 2;

    final path = Path();

    path.moveTo(rect.left + notchWidth, rect.top);
    path.lineTo(rect.right - radius, rect.top);
    path.quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius);

    path.lineTo(rect.right, rect.bottom - radius);
    path.quadraticBezierTo(rect.right, rect.bottom, rect.right - radius, rect.bottom);

    path.lineTo(rect.left + notchWidth, rect.bottom);
    path.lineTo(rect.left, rect.top + notchHeight);
    path.close();

    return path;
  }

  @override
  ShapeBorder scale(double t) => this;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);
}
