import 'package:flutter/material.dart';

/// 顯示確認刪除的對話框
Future<bool> showConfirmDeleteDialog(BuildContext context, {String? message}) async {
  final result = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('確認刪除'),
          content: Text(message ?? '您確定要刪除這筆資料嗎？'),
          actions: [
            TextButton(child: const Text('取消'), onPressed: () => Navigator.of(ctx).pop(false)),
            TextButton(
              child: const Text('刪除', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
  );

  return result ?? false;
}
