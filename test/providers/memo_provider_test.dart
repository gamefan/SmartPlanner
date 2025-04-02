import 'package:flutter_test/flutter_test.dart';
import 'package:smartplanner/providers/memo_provider.dart';
import 'package:smartplanner/models/memo_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // 必須放在最前面初始化 mock 儲存資料
  SharedPreferences.setMockInitialValues({});
  TestWidgetsFlutterBinding.ensureInitialized();
  group('MemoNotifier', () {
    test('addMemo should add a memo to state', () {
      final container = ProviderContainer();
      final notifier = container.read(memoProvider.notifier);

      final item = MemoItem(id: '1', content: '寫測試', type: MemoType.todo, createdAt: DateTime.now());

      notifier.addMemo(item);

      expect(container.read(memoProvider), contains(item));
    });

    test('toggleTodoStatus should toggle isCompleted', () {
      final container = ProviderContainer();
      final notifier = container.read(memoProvider.notifier);

      final item = MemoItem(id: '1', content: '看書', type: MemoType.todo, createdAt: DateTime.now(), isCompleted: false);

      notifier.addMemo(item);
      notifier.toggleTodoStatus('1');

      final updated = container.read(memoProvider).firstWhere((e) => e.id == '1');
      expect(updated.isCompleted, true);
    });

    test('getTodosByDate should return correct items', () {
      final container = ProviderContainer();
      final notifier = container.read(memoProvider.notifier);

      final today = DateTime.now();
      final item1 = MemoItem(id: '1', content: '早上運動', type: MemoType.todo, createdAt: today);
      final item2 = MemoItem(id: '2', content: '日記', type: MemoType.note, createdAt: today);

      notifier.addMemo(item1);
      notifier.addMemo(item2);

      final todos = notifier.getTodosByDate(today);
      expect(todos.length, 1);
      expect(todos.first.type, MemoType.todo);
    });

    test('deleteMemo should remove memo by id', () async {
      final container = ProviderContainer();
      final notifier = container.read(memoProvider.notifier);

      final item = MemoItem(id: '1', content: '刪除我', type: MemoType.note, createdAt: DateTime.now());

      await notifier.addMemo(item);
      await notifier.deleteMemo('1');

      final current = container.read(memoProvider);
      expect(current.any((m) => m.id == '1'), false);
    });
  });
}
