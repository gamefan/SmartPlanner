/*
負責處理首頁中所有與 UI 有關的邏輯，例如：

管理目前選取日期
處理文字輸入與語音輸入結果
呼叫 MemoProvider 新增 / 更新 / 刪除
根據選取日期取得備註與待辦清單
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/providers/memo_provider.dart';
import 'package:smartplanner/models/memo_item.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/core/utils/util.dart';

/// HomeViewModel 用於管理首頁相關狀態與操作
class HomeViewModel extends StateNotifier<HomeState> {
  final Ref ref;

  HomeViewModel(this.ref) : super(HomeState());

  /// 更新選取的日期
  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  /// 更新輸入中的內容
  void updateInput(String input) {
    state = state.copyWith(inputText: input);
  }

  /// 清空輸入框
  void clearInput() {
    state = state.copyWith(inputText: '');
  }

  /// 更新語音輸入的狀態
  void updateSpeechStatus(SpeechStatus status) {
    state = state.copyWith(speechStatus: status);
  }

  /// 切換下方展開狀態
  void toggleBottomExpanded() {
    state = state.copyWith(isBottomExpanded: !state.isBottomExpanded);
  }

  /// 設定下方展開狀態
  void setBottomExpanded(bool expanded) {
    state = state.copyWith(isBottomExpanded: expanded);
  }

  /// 新增備註或待辦（實際送出）
  Future<void> submitMemo({required MemoType type}) async {
    final memo = MemoItem(
      id: generateId(),
      content: state.inputText.trim(),
      type: type,
      createdAt: state.selectedDate,
      timeRangeType: type == MemoType.todo ? getTimeRangeTypeFromDateTime(state.selectedDate) : TimeRangeType.none,
    );

    await ref.read(memoProvider.notifier).addMemo(memo);
    clearInput();
  }

  /// 取得當日備註清單
  List<MemoItem> get notesForSelectedDate =>
      ref
          .read(memoProvider)
          .where((m) => m.type == MemoType.note && isSameDay(m.createdAt, state.selectedDate))
          .toList();

  /// 取得當日待辦清單
  List<MemoItem> get todosForSelectedDate =>
      ref
          .read(memoProvider)
          .where((m) => m.type == MemoType.todo && isSameDay(m.createdAt, state.selectedDate))
          .toList();

  /// 判斷是否為同一天
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// UI 狀態類別
class HomeState {
  /// 當前選取的日期
  final DateTime selectedDate;

  /// 輸入的文字內容
  final String inputText;

  /// 語音輸入的狀態
  final SpeechStatus speechStatus;

  /// 是否為下方滿版模式
  final bool isBottomExpanded;

  /// 建構子
  HomeState({
    DateTime? selectedDate,
    this.inputText = '',
    this.speechStatus = SpeechStatus.idle,
    this.isBottomExpanded = false,
  }) : selectedDate = selectedDate ?? DateTime.now();

  /// 複製當前狀態並更新部分屬性
  HomeState copyWith({DateTime? selectedDate, String? inputText, SpeechStatus? speechStatus, bool? isBottomExpanded}) {
    return HomeState(
      selectedDate: selectedDate ?? this.selectedDate,
      inputText: inputText ?? this.inputText,
      speechStatus: speechStatus ?? this.speechStatus,
      isBottomExpanded: isBottomExpanded ?? this.isBottomExpanded,
    );
  }
}

/// HomeViewModel 的 Provider
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) => HomeViewModel(ref));
