import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/features/memo/widgets/hashtag_filter_bar.dart';
import 'package:smartplanner/features/memo/widgets/memo_empty_placeholder.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/providers/memo_provider.dart';
import 'package:smartplanner/features/memo/widgets/memo_list_item.dart';
import 'package:smartplanner/features/memo/widgets/memo_filter_bar.dart';

/// 顯示所有 Memo（備註與待辦）的總覽頁面
class AllMemoPage extends ConsumerStatefulWidget {
  const AllMemoPage({super.key});

  @override
  ConsumerState<AllMemoPage> createState() => _AllMemoPageState();
}

class _AllMemoPageState extends ConsumerState<AllMemoPage> {
  MemoType? typeFilter; // 篩選：null = 全部
  bool? completedFilter; // 篩選：null = 全部，true = 完成，false = 未完成
  Set<String> selectedIds = {}; // 多選 Hashtag 篩選 ID

  @override
  Widget build(BuildContext context) {
    final allMemos = ref.watch(memoProvider);

    // 篩選處理
    final filtered =
        allMemos.where((memo) {
          final typeOk = typeFilter == null || memo.type == typeFilter;

          final completedOk =
              completedFilter == null ||
              memo.type == MemoType.note || // 備註忽略完成狀態
              (memo.type == MemoType.todo && (memo.isCompleted ?? false) == completedFilter);

          final hashtagOk =
              selectedIds.isEmpty || selectedIds.every((id) => memo.hashtags.contains(id)); // ✅ 每個被選的 hashtag 都要符合

          return typeOk && completedOk && hashtagOk;
        }).toList();

    // 排序處理
    filtered.sort((a, b) {
      // 1. 先依照類型排序（TODO 在前）
      if (a.type != b.type) {
        return a.type == MemoType.todo ? -1 : 1;
      }
      // 2. 同一類型，依照時間新到舊
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('所有記事'), centerTitle: true),
      body: Column(
        children: [
          // 過濾列
          MemoFilterBar(
            selectedType: typeFilter,
            selectedCompleted: completedFilter,
            onTypeChanged: (type) => setState(() => typeFilter = type),
            onCompletedChanged: (completed) => setState(() => completedFilter = completed),
          ),

          // 新增 Hashtag 篩選條
          HashtagFilterBar(
            selectedHashtagIds: selectedIds,
            onSelectionChanged: (newIds) => setState(() => selectedIds = newIds),
          ),

          const Divider(height: 1),

          // 清單內容
          Expanded(
            child:
                filtered.isEmpty
                    ? const MemoEmptyPlaceholder()
                    : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final memo = filtered[index];
                        return MemoListItem(memo: memo);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
