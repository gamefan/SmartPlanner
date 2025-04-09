import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/features/home/home_view_model.dart';
import 'package:smartplanner/models/enum.dart';
import 'dart:math';

import 'package:smartplanner/providers/hashtag_provider.dart'; // ⬅️ 記得加在檔案最上方

/// 頁面下方的輸入欄位區塊，支援文字與語音輸入
class MemoInputSection extends ConsumerWidget {
  const MemoInputSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final inputText = ref.watch(homeViewModelProvider).inputText;

    return Row(
      children: [
        // 語音按鈕（未實作）
        IconButton(
          icon: const Icon(Icons.mic),
          onPressed: () {
            // TODO: 未來加入語音輸入邏輯
          },
        ),

        // 輸入框
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: '輸入備註或待辦內容',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            controller: TextEditingController(text: inputText)
              ..selection = TextSelection.collapsed(offset: inputText.length),
            onChanged: viewModel.updateInput,
          ),
        ),

        // 傳送按鈕
        IconButton(
          icon: const Icon(Icons.send),
          onPressed:
              inputText.trim().isEmpty
                  ? null
                  : () async {
                    // 🔧 測試用：隨機決定是備註還是待辦
                    final isTodo = Random().nextBool();
                    final type = isTodo ? MemoType.todo : MemoType.note;

                    // 🔧 測試用：隨機取出 0～3 個 hashtag 的 id
                    final allTags = ref.read(hashtagProvider);
                    final random = Random();
                    final shuffled = allTags.toList()..shuffle();
                    final selected = shuffled.take(random.nextInt(4)).map((tag) => tag.id).toList();

                    await viewModel.submitMemo(type: type, hashtags: selected);
                  },
        ),
      ],
    );
  }
}
