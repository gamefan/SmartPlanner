import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/core/utils/dialog_util.dart';
import 'package:smartplanner/features/home/home_view_model.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/models/memo_item.dart';
import 'package:smartplanner/providers/memo_provider.dart';
import 'package:smartplanner/widgets/memo_hashtag_row.dart';

/// 顯示當前選取日期的待辦與備註清單，可展開／收合
class MemoListSection extends ConsumerStatefulWidget {
  const MemoListSection({super.key});

  @override
  ConsumerState<MemoListSection> createState() => _MemoListSectionState();
}

class _MemoListSectionState extends ConsumerState<MemoListSection> {
  bool _todosExpanded = true;
  bool _notesExpanded = true;

  @override
  Widget build(BuildContext context) {
    final memos = ref.watch(memoProvider);
    final selectedDate = ref.watch(homeViewModelProvider).selectedDate;

    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    final todos = memos.where((m) => m.type == MemoType.todo && isSameDay(m.createdAt, selectedDate)).toList();
    final notes = memos.where((m) => m.type == MemoType.note && isSameDay(m.createdAt, selectedDate)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todos.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              title: const Text('待辦事項', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Icon(_todosExpanded ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() => _todosExpanded = !_todosExpanded),
            ),
          ),
          if (_todosExpanded) ...todos.map((item) => _TodoTile(item: item)),
        ],
        if (notes.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Color(0xFFFFF4EC), borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('備註', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Icon(_notesExpanded ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() => _notesExpanded = !_notesExpanded),
            ),
          ),
          if (_notesExpanded) ...notes.map((item) => _NoteTile(item: item)),
        ],
      ],
    );
  }
}

/// 待辦項目 tile（可勾選與刪除）
class _TodoTile extends ConsumerWidget {
  final MemoItem item;
  const _TodoTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.read(memoProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE), // 非常淡的灰（你可以調成 0xFFF2F2F2 更淡）
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text(
              item.content,
              style: TextStyle(fontSize: 16, decoration: item.isCompleted == true ? TextDecoration.lineThrough : null),
            ),
            subtitle:
                item.targetTime != null
                    ? Text('時間：${item.targetTime!.hour}:${item.targetTime!.minute.toString().padLeft(2, '0')}')
                    : null,
            leading: Checkbox(value: item.isCompleted ?? false, onChanged: (_) => provider.toggleTodoStatus(item.id)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showConfirmDeleteDialog(context);
                if (confirm) {
                  provider.deleteMemo(item.id);
                }
              },
            ),
          ),
          if (item.hashtags.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
                child: MemoHashtagRow(hashtagIds: item.hashtags),
              ),
            ),
        ],
      ),
    );
  }
}

/// 備註 tile（只能顯示與刪除）
class _NoteTile extends ConsumerWidget {
  final MemoItem item;
  const _NoteTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.read(memoProvider.notifier);
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE), // 非常淡的灰
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            title: Text(item.content, style: const TextStyle(fontSize: 16)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showConfirmDeleteDialog(context);
                if (confirm) {
                  provider.deleteMemo(item.id);
                }
              },
            ),
          ),
          if (item.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
              child: MemoHashtagRow(hashtagIds: item.hashtags),
            ),
        ],
      ),
    );
  }
}
