import 'package:flutter/material.dart';

/// 當清單為空時顯示的提示元件
class MemoEmptyPlaceholder extends StatelessWidget {
  final String message;

  const MemoEmptyPlaceholder({super.key, this.message = '尚無資料'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
