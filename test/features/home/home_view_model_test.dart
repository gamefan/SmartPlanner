/*
測試內容涵蓋：
選擇日期
更新與清除輸入
語音狀態控制
新增備註與待辦（整合 memoProvider）
查詢資料是否正確分類
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartplanner/features/home/home_view_model.dart';
import 'package:smartplanner/models/enum.dart';

void main() {
  // 必須放在最前面初始化 mock 儲存資料
  SharedPreferences.setMockInitialValues({});
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeViewModel', () {
    late ProviderContainer container;
    late HomeViewModel viewModel;

    setUp(() {
      container = ProviderContainer();
      viewModel = container.read(homeViewModelProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('selectDate updates selectedDate in state', () {
      final now = DateTime.now();
      final tomorrow = now.add(Duration(days: 1));

      viewModel.selectDate(tomorrow);

      expect(container.read(homeViewModelProvider).selectedDate, tomorrow);
    });

    test('updateInput and clearInput work correctly', () {
      viewModel.updateInput('今天記得喝水');
      expect(container.read(homeViewModelProvider).inputText, '今天記得喝水');

      viewModel.clearInput();
      expect(container.read(homeViewModelProvider).inputText, '');
    });

    test('updateSpeechStatus updates state correctly', () {
      viewModel.updateSpeechStatus(SpeechStatus.listening);
      expect(container.read(homeViewModelProvider).speechStatus, SpeechStatus.listening);
    });

    test('submitMemo adds note and clears input', () async {
      viewModel.updateInput('這是一筆備註');
      await viewModel.submitMemo(type: MemoType.note);

      final notes = viewModel.notesForSelectedDate;
      expect(notes.length, 1);
      expect(notes.first.content, '這是一筆備註');
      expect(notes.first.type, MemoType.note);
      expect(container.read(homeViewModelProvider).inputText, '');
    });

    test('submitMemo adds todo with correct type', () async {
      viewModel.updateInput('晚上去慢跑');
      await viewModel.submitMemo(type: MemoType.todo);

      final todos = viewModel.todosForSelectedDate;
      expect(todos.length, 1);
      expect(todos.first.content, '晚上去慢跑');
      expect(todos.first.type, MemoType.todo);
      expect(todos.first.timeRangeType, isNot(TimeRangeType.none));
    });
  });
}
