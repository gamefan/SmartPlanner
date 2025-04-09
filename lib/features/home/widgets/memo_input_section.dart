import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/core/services/input_analyzer/hashtag_input_analyzer.dart';
import 'package:smartplanner/core/services/input_analyzer/memo_input_analyzer.dart';
import 'package:smartplanner/core/utils/util.dart';
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

                    // 🔍 取得目前所有 hashtag 清單（比對是否已存在）
                    final allTags = ref.read(hashtagProvider);
                    final hashtagNotifier = ref.read(hashtagProvider.notifier);
                    final tagIds = <String>[];

                    // 🔄 對分析出來的 hashtag 名稱逐一處理
                    for (final tagName in analysis.hashtags) {
                      final match = allTags.firstWhere((t) => t.name == tagName, orElse: () => Hashtag.empty());

                      if (match.id.isNotEmpty) {
                        // ✅ 已存在的 hashtag，直接加入 id 清單
                        tagIds.add(match.id);
                      } else {
                        // ✨ 不存在的 hashtag，自動建立新項目
                        final category = await HashtagInputAnalyzer.analyzeCategory(tagName);
                        final newTag = Hashtag(
                          id: generateId(),
                          name: tagName,
                          source: HashtagSource.aiGenerated,
                          category: category,
                        );
                        hashtagNotifier.addHashtag(newTag);
                        tagIds.add(newTag.id);
                      }
                    }

                    // ✅ 送出 Memo，包含分析得到的類型、時間與 hashtag id 清單
                    await viewModel.submitMemo(
                      type: analysis.type,
                      timeRangeType: analysis.timeRangeType,
                      hashtags: tagIds,
                    );
                  },
        ),
      ],
    );
  }
}
