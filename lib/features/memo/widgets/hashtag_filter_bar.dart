import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/models/hashtag.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/providers/hashtag_provider.dart';

/// Hashtag 篩選列（多選，自訂底圖樣式）
class HashtagFilterBar extends ConsumerWidget {
  final Set<String> selectedHashtagIds;
  final void Function(Set<String>) onSelectionChanged;

  const HashtagFilterBar({super.key, required this.selectedHashtagIds, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTags = ref.watch(hashtagProvider);

    // 根據分類排序
    final grouped = <HashtagCategory, List<Hashtag>>{};
    for (final tag in allTags) {
      grouped.putIfAbsent(tag.category, () => []).add(tag);
    }

    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (final category in HashtagCategory.values)
              if (grouped.containsKey(category)) ...[
                const SizedBox(width: 6),
                for (final tag in grouped[category]!)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(tag.name, style: const TextStyle(fontSize: 15)),
                      selected: selectedHashtagIds.contains(tag.id),
                      onSelected: (_) {
                        final newSet = Set<String>.from(selectedHashtagIds);
                        if (newSet.contains(tag.id)) {
                          newSet.remove(tag.id);
                        } else {
                          newSet.add(tag.id);
                        }
                        onSelectionChanged(newSet);
                      },
                      shape: const _TagLabelShapeBorder(),
                      selectedColor: Colors.blue.shade100,
                      backgroundColor:
                          tag.source == HashtagSource.aiGenerated ? const Color(0xFFCFD8DC) : const Color(0xFFFFF59D),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8), // 左側多加點空間
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

/// 自定義形狀：圓角矩形 + 左側尖角
class _TagLabelShapeBorder extends OutlinedBorder {
  const _TagLabelShapeBorder();

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.only(left: 0); // 和 notchWidth 對齊

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const radius = 4.0;
    const notchWidth = 10.0;
    final notchHeight = rect.height / 2;

    final path = Path();

    path.moveTo(rect.left + notchWidth, rect.top); // 從 notch 右側開始
    path.lineTo(rect.right - radius, rect.top);
    path.quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius);

    path.lineTo(rect.right, rect.bottom - radius);
    path.quadraticBezierTo(rect.right, rect.bottom, rect.right - radius, rect.bottom);

    path.lineTo(rect.left + notchWidth, rect.bottom); // 回到左側 notch 右側
    path.lineTo(rect.left, rect.top + notchHeight); // 尖角
    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  OutlinedBorder copyWith({BorderSide? side}) => this;
}
