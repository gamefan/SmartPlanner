import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/models/memo_item.dart';
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

  @override
  Widget build(BuildContext context) {
    final allMemos = ref.watch(memoProvider);

    // 篩選處理
    final filtered =
        allMemos.where((memo) {
            final typeOk = typeFilter == null || memo.type == typeFilter;
            final completedOk =
                completedFilter == null ||
                (memo.type == MemoType.todo && memo.isCompleted == completedFilter) ||
                memo.type == MemoType.note;
            return typeOk && completedOk;
          }).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 時間排序（新到舊）

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

          const Divider(height: 1),

          // 清單內容
          Expanded(
            child:
                filtered.isEmpty
                    ? const Center(child: Text('目前沒有任何資料'))
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
