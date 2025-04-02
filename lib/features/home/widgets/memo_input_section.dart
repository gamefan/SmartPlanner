import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/features/home/home_view_model.dart';
import 'package:smartplanner/models/enum.dart';

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
                    // TODO: 預設新增為備註，之後可根據 AI 分析判斷
                    await viewModel.submitMemo(type: MemoType.note);
                  },
        ),
      ],
    );
  }
}
