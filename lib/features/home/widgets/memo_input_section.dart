import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:smartplanner/core/services/input_analyzer/hashtag_input_analyzer.dart';
import 'package:smartplanner/core/services/input_analyzer/memo_input_analyzer.dart';
import 'package:smartplanner/core/services/notification_service.dart';
import 'package:smartplanner/core/services/speech_input_service.dart';
import 'package:smartplanner/core/services/storage_service.dart';
import 'package:smartplanner/core/utils/util.dart';
import 'package:smartplanner/features/home/home_view_model.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/models/hashtag.dart';

import 'package:smartplanner/providers/hashtag_provider.dart';
import 'package:smartplanner/widgets/voice_input_dialog.dart';
import 'package:table_calendar/table_calendar.dart';

/// 頁面下方的輸入欄位區塊，支援文字與語音輸入
class MemoInputSection extends ConsumerStatefulWidget {
  const MemoInputSection({super.key});

  @override
  ConsumerState<MemoInputSection> createState() => _MemoInputSectionState();
}

class _MemoInputSectionState extends ConsumerState<MemoInputSection> {
  final _speechService = SpeechInputService();
  late final FocusNode _focusNode;
  bool _isLoading = false;

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
    // AI 分析中的 loading 狀態
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('AI 分析中…請稍候', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

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

  /// 提交備註或待辦
  Future<void> _handleSubmit() async {
    /*
        AI + fallback 的語意分析
        自動產生與分類 hashtag
        自動推斷 targetTime
        自動根據設定建立 notificationTime
        比對現有通知 ID，避免重複
        呼叫 NotificationService.scheduleNotification
        傳入 notificationTime 與 notificationId 給 submitMemo
    */

    // 變更 loading 狀態
    setState(() => _isLoading = true);

    final viewModel = ref.read(homeViewModelProvider.notifier);
    final inputText = ref.read(homeViewModelProvider).inputText.trim();

    if (inputText.isEmpty) {
      setState(() => _isLoading = false); // 還原狀態
      return;
    }

    final selectedDate = ref.read(homeViewModelProvider).selectedDate;
    final analysis = await MemoInputAnalyzer.analyze(inputText, selectedDate);

    final allTags = ref.read(hashtagProvider);
    final hashtagNotifier = ref.read(hashtagProvider.notifier);
    final tagIds = <String>[];

    // 若 AI 沒給 targetTime 且是 todo，就 fallback 使用 rule-based 預設時間
    final targetTime =
        analysis.targetTime ??
        (analysis.type == MemoType.todo ? selectedDate.toTargetTime(analysis.timeRangeType) : null);

    // hashtag 生成與分類
    for (final tagName in analysis.hashtags) {
      final match = allTags.firstWhere((t) => t.name == tagName, orElse: () => Hashtag.empty());
      // 如果 tagName 已存在，則直接使用其 ID
      if (match.id.isNotEmpty) {
        tagIds.add(match.id);
      } else {
        // 如果 tagName 不存在，則使用 AI 生成的分類
        final category = await HashtagInputAnalyzer.analyzeCategory(tagName);
        final newTag = Hashtag(id: generateId(), name: tagName, source: HashtagSource.aiGenerated, category: category);
        hashtagNotifier.addHashtag(newTag);
        tagIds.add(newTag.id);
      }
    }

    // 輸入內容的判斷，看使否要使用AI調整過的內容
    final contentToUse =
        (targetTime != null && !isSameDay(targetTime, selectedDate)) ? analysis.adjustedContent : inputText;

    // 通知相關資料
    DateTime? notificationTime;
    int? notificationId;

    // 🔔 建立通知判斷條件
    if (analysis.type == MemoType.todo && targetTime != null && targetTime.isAfter(DateTime.now())) {
      final storage = StorageService();
      final earliest = await storage.loadEarliestHour() ?? 8;
      final latest = await storage.loadLatestHour() ?? 22;
      final behavior = await storage.loadOutOfRangeBehavior() ?? 'skip';

      // 設定通知時間
      // 如果時間在最早與最晚之間，則使用 targetTime
      // 調整模式(adjust)如果時間在最早之前，則調整為最早時間，如果時間在最晚之後，則使用最晚時間
      // skip 模式則不建立通知
      final hour = targetTime.hour;
      if (hour < earliest && behavior == 'adjust') {
        notificationTime = DateTime(targetTime.year, targetTime.month, targetTime.day, earliest);
      } else if (hour > latest && behavior == 'adjust') {
        notificationTime = DateTime(targetTime.year, targetTime.month, targetTime.day, latest);
      } else if (hour < earliest || hour > latest) {
        notificationTime = null; // skip 建立
      } else {
        notificationTime = targetTime;
      }

      // 🔁 避免 ID 重複
      if (notificationTime != null) {
        final pending = await NotificationService.getPendingNotifications();
        final usedIds = pending.map((p) => p.id).toSet();

        int newId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
        while (usedIds.contains(newId)) {
          newId = (newId + 1) % 1000000;
        }

        notificationId = newId;

        await NotificationService.scheduleNotification(
          id: notificationId,
          title: '待辦提醒',
          body: contentToUse,
          scheduledTime: notificationTime,
        );
      }
    }

    // 傳入 notificationTime 與 notificationId
    await viewModel.submitMemo(
      type: analysis.type,
      timeRangeType: analysis.timeRangeType,
      content: contentToUse,
      hashtags: tagIds,
      targetTime: targetTime,
      notificationTime: notificationTime,
      notificationId: notificationId,
    );

    // 清空輸入欄位
    _focusNode.unfocus();

    // 還原 loading 狀態
    setState(() => _isLoading = false);

    final time = targetTime ?? selectedDate;
    final label = (analysis.type == MemoType.todo) ? "待辦事項" : "備註內容";
    final formatted = DateFormat('MM/dd').format(time);

    final msg = "已新增 $label，記錄於 $formatted";
    Fluttertoast.showToast(msg: msg, toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
  }
}
