import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:smartplanner/core/utils/dialog_util.dart';
import 'package:smartplanner/models/memo_item.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/providers/memo_provider.dart';
import 'package:smartplanner/widgets/memo_hashtag_row.dart';
import 'package:smartplanner/features/home/widgets/edit_memo_dialog.dart';

/// 顯示一筆 Memo 項目（備註或待辦）
class MemoListItem extends ConsumerStatefulWidget {
  final MemoItem memo;
  const MemoListItem({super.key, required this.memo});

  @override
  ConsumerState<MemoListItem> createState() => _MemoListItemState();
}

class _MemoListItemState extends ConsumerState<MemoListItem> {
  bool _longPressTriggered = false;

  void _handlePressStart(BuildContext context) {
    _longPressTriggered = false;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _longPressTriggered) return;
      _longPressTriggered = true;

      final slidable = Slidable.of(context);
      if (slidable != null) {
        final currentType = slidable.actionPaneType.value;
        if (currentType == ActionPaneType.start) {
          slidable.close();
        } else {
          slidable.openStartActionPane();
        }
      }
    });
  }

  void _handleCancel() {
    _longPressTriggered = true;
  }

  @override
  Widget build(BuildContext context) {
    final memo = widget.memo;
    final provider = ref.read(memoProvider.notifier);

    return Slidable(
      key: ValueKey(memo.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) async {
              await showDialog(
                context: context,
                barrierDismissible: false,
                // 選擇日期使用createdAt，開啟編輯子畫面
                builder: (_) => EditMemoDialog(item: memo, selectedDate: memo.createdAt),
              );
            },
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '編輯',
            flex: 2,
          ),
          SlidableAction(
            onPressed: (_) async {
              final confirm = await showConfirmDeleteDialog(context);
              if (confirm) {
                provider.deleteMemo(memo.id);
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '刪除',
            flex: 2,
          ),
        ],
      ),
      child: Builder(
        builder: (slidableContext) {
          return Listener(
            onPointerDown: (_) => _handlePressStart(slidableContext),
            onPointerUp: (_) => _handleCancel(),
            child: Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1))),
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
                      style: TextStyle(
                        fontSize: 16,
                        decoration: memo.isCompleted == true ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(_buildSubtitle(memo), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    if (memo.hashtags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      MemoHashtagRow(hashtagIds: memo.hashtags),
                    ],
                  ],
                ),
                trailing:
                    memo.type == MemoType.todo
                        ? Checkbox(
                          value: memo.isCompleted ?? false,
                          onChanged: (_) => provider.toggleTodoStatus(memo.id),
                        )
                        : null,
              ),
            ),
          );
        },
      ),
    );
  }

  String _buildSubtitle(MemoItem memo) {
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
