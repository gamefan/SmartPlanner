import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/core/utils/dialog_util.dart';
import 'package:smartplanner/models/memo_item.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/providers/memo_provider.dart';
import 'package:smartplanner/widgets/memo_hashtag_row.dart';

/// 顯示一筆 Memo 項目（備註或待辦）
class MemoListItem extends ConsumerWidget {
  final MemoItem memo;

  const MemoListItem({super.key, required this.memo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.read(memoProvider.notifier);
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE), // 非常淡的灰色底線
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          memo.type == MemoType.todo ? Icons.check_circle_outline : Icons.edit_note,
          color: memo.type == MemoType.todo ? Colors.green : Colors.blue,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              memo.content,
              style: TextStyle(fontSize: 16, decoration: memo.isCompleted == true ? TextDecoration.lineThrough : null),
            ),
            const SizedBox(height: 1),
            Text(_buildSubtitle(), style: const TextStyle(fontSize: 13, color: Colors.grey)),
            if (memo.hashtags.isNotEmpty) ...[const SizedBox(height: 4), MemoHashtagRow(hashtagIds: memo.hashtags)],
          ],
        ),
        subtitle: null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (memo.type == MemoType.todo)
              Checkbox(value: memo.isCompleted ?? false, onChanged: (_) => provider.toggleTodoStatus(memo.id)),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showConfirmDeleteDialog(context);
                if (confirm) {
                  provider.deleteMemo(memo.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 建立 subtitle 顯示內容（建立時間或時間區段）
  String _buildSubtitle() {
    final dt = memo.targetTime ?? memo.createdAt;
    final dateStr = '${dt.year}/${dt.month}/${dt.day}';
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (memo.type == MemoType.todo && memo.targetTime != null) {
      return '待辦時間：$dateStr $timeStr';
    } else {
      return '建立於：$dateStr';
    }
  }
}
