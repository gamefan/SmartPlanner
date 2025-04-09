import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/core/services/input_analyzer/memo_input_analyzer.dart';
import 'package:smartplanner/features/home/home_view_model.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/models/hashtag.dart';
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
                    // 🧠 實際解析輸入內容
                    final analysis = await MemoInputAnalyzer.analyze(inputText.trim());

                    // 提取已存在的 hashtag 資訊，轉換為 id 清單
                    final allTags = ref.read(hashtagProvider);
                    final existingTags = <String>[];

                    for (final tag in analysis.hashtags) {
                      final match = allTags.firstWhere(
                        (t) => t.name == tag,
                        orElse: () => Hashtag.empty(), // 你應該要有 empty() 預設值
                      );

                      if (match.id.isNotEmpty) {
                        existingTags.add(match.id);
                      }
                    }

                    await viewModel.submitMemo(
                      type: analysis.type,
                      timeRangeType: analysis.timeRangeType,
                      hashtags: existingTags,
                    );
                  },
        ),
      ],
    );
  }
}
