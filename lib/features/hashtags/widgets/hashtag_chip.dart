import 'package:flutter/material.dart';
import 'package:smartplanner/models/hashtag.dart';

/// 顯示單一 Hashtag 的自定義 Tag 樣式
class HashtagChip extends StatelessWidget {
  final Hashtag tag;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const HashtagChip({
    super.key,
    required this.tag,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAi = tag.source.name == 'aiGenerated';
    final bgColor =
        isSelected
            ? Colors.blue.shade200
            : isAi
            ? const Color(0xFFC2CDD3) // 鐵灰
            : const Color(0xFFF0E58F); // 黃膚

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
          decoration: ShapeDecoration(
            color: bgColor,
            shape: const _LabelShapeBorder(), // 自定義形狀
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tag.name, style: const TextStyle(fontSize: 14)),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                GestureDetector(onTap: onDelete, child: const Icon(Icons.close, size: 16)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 自定義形狀：圓角矩形 + 銳角弧形
/// 這個形狀是為了讓 Hashtag 的 Tag 看起來像一個標籤，並且有一個尖端的弧形
class _LabelShapeBorder extends ShapeBorder {
  const _LabelShapeBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final tagHeight = rect.height;
    final notch = tagHeight / 2;

    final path = Path();
    path.moveTo(rect.left + notch, rect.top);
    path.lineTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.left + notch, rect.bottom);

    // 弧角取代銳角：由下往中間畫一條貝茲曲線到上方
    path.quadraticBezierTo(
      rect.left, // 控制點（弧形尖端位置）
      rect.top + tagHeight / 2, // 垂直中心
      rect.left + notch, // 終點 x
      rect.top, // 終點 y
    );

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
