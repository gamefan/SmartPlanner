import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/core/services/notification_service.dart';
import 'package:smartplanner/core/services/storage_service.dart';
import 'package:smartplanner/core/utils/util.dart';
import 'package:smartplanner/features/home/home_view_model.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/models/memo_item.dart';
import 'package:smartplanner/providers/memo_provider.dart';
import 'package:intl/intl.dart';

class EditMemoDialog extends ConsumerStatefulWidget {
  final MemoItem item;

  const EditMemoDialog({super.key, required this.item});

  @override
  ConsumerState<EditMemoDialog> createState() => _EditMemoDialogState();
}

class _EditMemoDialogState extends ConsumerState<EditMemoDialog> {
  late MemoType _type;
  late TextEditingController _contentController;
  DateTime? _targetTime;

  @override
  void initState() {
    super.initState();
    _type = widget.item.type;
    _contentController = TextEditingController(text: widget.item.content);
    _targetTime = widget.item.targetTime;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 顯示時間選擇器，並更新目標時間
  Future<void> _pickTime(BuildContext context) async {
    final calendarDate = ref.read(homeViewModelProvider).selectedDate;

    // 初始時間使用 targetTime，有的話帶時間，沒有的話只用日期的 00:00
    final baseTime = _targetTime ?? calendarDate;
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(baseTime));

    if (picked != null) {
      setState(() {
        _targetTime = DateTime(calendarDate.year, calendarDate.month, calendarDate.day, picked.hour, picked.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // 背景為白
      title: const Text('編輯項目'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                labelText: '類型',
                border: OutlineInputBorder(), // ✅ 加框線
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MemoType>(
                  value: _type,
                  isExpanded: true,
                  items:
                      MemoType.values.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type == MemoType.todo ? '待辦事項' : '備註'));
                      }).toList(),
                  onChanged: (value) => setState(() => _type = value!),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '內容', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _type == MemoType.todo ? () => _pickTime(context) : null,
              behavior: HitTestBehavior.opaque, // 即使點在空白處也會觸發
              child: Row(
                children: [
                  Icon(Icons.access_time, color: _type == MemoType.todo ? Colors.blue : Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _type == MemoType.note
                        ? '無目標時間'
                        : (_targetTime != null ? DateFormat('HH:mm').format(_targetTime!) : '未設定時間'),
                    style: TextStyle(color: _type == MemoType.todo ? Colors.black87 : Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: () async {
            final content = _contentController.text.trim();
            if (content.isEmpty) return;

            // 根據內容與目標時間建立通知時間與 ID，並處理舊通知刪除
            final (notificationTime, notificationId) = await buildNotification(
              content,
              _type == MemoType.todo ? _targetTime : null,
              previousNotificationId: widget.item.notificationId,
            );

            final updated = widget.item.copyWith(
              content: content,
              type: _type,
              targetTime: _type == MemoType.todo ? _targetTime : null,
              timeRangeType:
                  _type == MemoType.todo && _targetTime != null
                      ? TimeRangeTypeExtension.fromHour(_targetTime!.hour)
                      : TimeRangeType.none,
              notificationTime: notificationTime,
              notificationId: notificationId,
            );

            // 更新狀態
            await ref.read(memoProvider.notifier).updateMemo(updated);

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }
}
