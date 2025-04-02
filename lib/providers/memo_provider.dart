import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/models/memo_item.dart';
import 'package:smartplanner/core/services/storage_service.dart';

/// Memo 狀態管理器（使用 StateNotifier）
class MemoNotifier extends StateNotifier<List<MemoItem>> {
  final StorageService storage;

  MemoNotifier(this.storage) : super([]);

  /// 初始化時從 SharedPreferences 載入資料
  Future<void> init() async {
    final loaded = await storage.loadMemos();
    state = loaded;
  }

  /// 新增一筆備註或待辦項目
  Future<void> addMemo(MemoItem item) async {
    state = [...state, item];
    await storage.saveMemos(state);
  }

  /// 根據 ID 刪除一筆項目（備註或待辦）
  Future<void> deleteMemo(String id) async {
    state = state.where((item) => item.id != id).toList();
    await storage.saveMemos(state);
  }

  /// 根據 ID 更新完成狀態（僅適用於 todo）
  Future<void> toggleTodoStatus(String id) async {
    state = [
      for (final item in state)
        if (item.id == id && item.type == MemoType.todo)
          item.copyWith(isCompleted: !(item.isCompleted ?? false))
        else
          item,
    ];
    await storage.saveMemos(state);
  }

  /// 取得某日期的所有資料
  List<MemoItem> getItemsByDate(DateTime date) {
    return state.where((item) {
      final itemDate = item.createdAt;
      return itemDate.year == date.year && itemDate.month == date.month && itemDate.day == date.day;
    }).toList();
  }

  /// 取得某日期的備註
  List<MemoItem> getNotesByDate(DateTime date) {
    return getItemsByDate(date).where((item) => item.type == MemoType.note).toList();
  }

  /// 取得某日期的待辦
  List<MemoItem> getTodosByDate(DateTime date) {
    return getItemsByDate(date).where((item) => item.type == MemoType.todo).toList();
  }

  /// 清空所有資料（重設）
  Future<void> clearAll() async {
    state = [];
    await storage.saveMemos(state);
  }
}

/// 提供 memo 狀態存取的 Riverpod provider
final memoProvider = StateNotifierProvider<MemoNotifier, List<MemoItem>>((ref) => MemoNotifier(StorageService()));
