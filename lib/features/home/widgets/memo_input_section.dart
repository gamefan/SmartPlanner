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
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _speechService.init();

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      _updateFloatingState();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _updateFloatingState() {
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final focus = _focusNode.hasFocus;
    final shouldFloat = focus || keyboardOpen;

    viewModel.setKeyboardFloating(shouldFloat);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final inputText = ref.watch(homeViewModelProvider).inputText;
    final isFloating = ref.watch(homeViewModelProvider).isKeyboardFloating;

    // 每一幀都同步檢查一次鍵盤狀態，避免卡死
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFloatingState());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isFloating ? 12 : 0),
        boxShadow: isFloating ? [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))] : null,
      ),
      child: Row(
        children: [
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
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: '輸入備註或待辦內容',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              controller: TextEditingController(text: inputText)
                ..selection = TextSelection.collapsed(offset: inputText.length),
              onChanged: viewModel.updateInput,
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: inputText.trim().isEmpty ? null : _handleSubmit),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final inputText = ref.read(homeViewModelProvider).inputText.trim();

    if (inputText.isEmpty) return;

    final analysis = await MemoInputAnalyzer.analyze(inputText);

    final allTags = ref.read(hashtagProvider);
    final hashtagNotifier = ref.read(hashtagProvider.notifier);
    final tagIds = <String>[];

    for (final tagName in analysis.hashtags) {
      final match = allTags.firstWhere((t) => t.name == tagName, orElse: () => Hashtag.empty());

      if (match.id.isNotEmpty) {
        tagIds.add(match.id);
      } else {
        final category = await HashtagInputAnalyzer.analyzeCategory(tagName);
        final newTag = Hashtag(id: generateId(), name: tagName, source: HashtagSource.aiGenerated, category: category);
        hashtagNotifier.addHashtag(newTag);
        tagIds.add(newTag.id);
      }
    }

    await viewModel.submitMemo(type: analysis.type, timeRangeType: analysis.timeRangeType, hashtags: tagIds);

    _focusNode.unfocus(); // ✅ 提交後自動取消焦點，關閉鍵盤
  }
}
