import 'package:flutter_test/flutter_test.dart';
import 'package:smartplanner/models/memo_item.dart';
import 'package:smartplanner/models/enum.dart';

void main() {
  group('MemoItem', () {
    test('isAllDayTodo should return true when type is todo and targetTime is null', () {
      final memo = MemoItem(id: '1', content: '去運動', type: MemoType.todo, createdAt: DateTime.now());

      expect(memo.isAllDayTodo, true);
      expect(memo.isTimedTodo, false);
    });

    test('isTimedTodo should return true when type is todo and targetTime is set', () {
      final memo = MemoItem(
        id: '2',
        content: '下午開會',
        type: MemoType.todo,
        createdAt: DateTime.now(),
        targetTime: DateTime(2024, 5, 1, 14, 0),
      );

      expect(memo.isTimedTodo, true);
      expect(memo.isAllDayTodo, false);
    });

    test('copyWith should return new instance with updated content', () {
      final original = MemoItem(id: '3', content: '原始內容', type: MemoType.note, createdAt: DateTime.now());

      final updated = original.copyWith(content: '更新後內容');

      expect(updated.id, original.id);
      expect(updated.content, '更新後內容');
      expect(updated.type, original.type);
    });
  });
}
