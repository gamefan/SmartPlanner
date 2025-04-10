import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/core/services/input_analyzer/hashtag_input_analyzer.dart';
import 'package:smartplanner/core/services/input_analyzer/memo_input_analyzer.dart';
import 'package:smartplanner/core/services/speech_input_service.dart';
import 'package:smartplanner/core/utils/util.dart';
import 'package:smartplanner/features/home/home_view_model.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/models/hashtag.dart';

import 'package:smartplanner/providers/hashtag_provider.dart';
import 'package:smartplanner/widgets/voice_input_dialog.dart';

/// 頁面下方的輸入欄位區塊，支援文字與語音輸入
class MemoInputSection extends ConsumerStatefulWidget {
  const MemoInputSection({super.key});

  @override
  ConsumerState<MemoInputSection> createState() => _MemoInputSectionState();
}

class _MemoInputSectionState extends ConsumerState<MemoInputSection> {
  final _speechService = SpeechInputService();

  @override
  void initState() {
    super.initState();
    _speechService.init();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final inputText = ref.watch(homeViewModelProvider).inputText;

    return Row(
      children: [
        // 🎤 語音按鈕
        IconButton(
          icon: const Icon(Icons.mic),
          onPressed: () {
            showVoiceInputDialog(
              context,
              onResult: (text) {
                ref.read(homeViewModelProvider.notifier).updateInput(text);
              },
            );
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
                    final analysis = await MemoInputAnalyzer.analyze(inputText.trim());

                    final allTags = ref.read(hashtagProvider);
                    final hashtagNotifier = ref.read(hashtagProvider.notifier);
                    final tagIds = <String>[];

                    for (final tagName in analysis.hashtags) {
                      final match = allTags.firstWhere((t) => t.name == tagName, orElse: () => Hashtag.empty());

                      if (match.id.isNotEmpty) {
                        tagIds.add(match.id);
                      } else {
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
