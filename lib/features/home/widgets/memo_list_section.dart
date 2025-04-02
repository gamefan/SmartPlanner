/*
顯示選取日期下的 待辦清單 與 備註清單
每一筆待辦支援：
勾選完成 / 未完成（✅）
刪除（🗑）
每一筆備註支援：
刪除
顯示簡單時間／狀態（若有 targetTime）

 後續可擴充點（暫時不加）：
顯示 hashtag tag chips
支援長按選擇多筆
支援滑動刪除／完成動畫
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/features/home/home_view_model.dart';
import 'package:smartplanner/models/memo_item.dart';
import 'package:smartplanner/providers/memo_provider.dart';

/// 顯示當前選取日期的待辦與備註清單
class MemoListSection extends ConsumerWidget {
  const MemoListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final todos = viewModel.todosForSelectedDate;
    final notes = viewModel.notesForSelectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 4),
            child: Text('待辦事項', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...todos.map((item) => _TodoTile(item: item)),
        ],
        if (notes.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 4),
            child: Text('備註', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...notes.map((item) => _NoteTile(item: item)),
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

    return ListTile(
      dense: true,
      title: Text(
        item.content,
        style: TextStyle(decoration: item.isCompleted == true ? TextDecoration.lineThrough : null),
      ),
      subtitle:
          item.targetTime != null
              ? Text('時間：${item.targetTime!.hour}:${item.targetTime!.minute.toString().padLeft(2, '0')}')
              : null,
      leading: Checkbox(value: item.isCompleted ?? false, onChanged: (_) => provider.toggleTodoStatus(item.id)),
      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => provider.deleteMemo(item.id)),
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

    return ListTile(
      dense: true,
      title: Text(item.content),
      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => provider.deleteMemo(item.id)),
    );
  }
}
