import 'package:flutter/material.dart';
import 'package:smartplanner/models/enum.dart';

/// 篩選列元件：可篩選類型（全部 / 備註 / 待辦）與狀態（全部 / 完成 / 未完成）
class MemoFilterBar extends StatelessWidget {
  final MemoType? selectedType;
  final bool? selectedCompleted;
  final ValueChanged<MemoType?> onTypeChanged;
  final ValueChanged<bool?> onCompletedChanged;

  const MemoFilterBar({
    super.key,
    required this.selectedType,
    required this.selectedCompleted,
    required this.onTypeChanged,
    required this.onCompletedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              FilterChip(
                label: const Text('全部', style: TextStyle(fontSize: 14)),
                selected: selectedType == null,
                onSelected: (_) => onTypeChanged(null),
              ),
              FilterChip(
                label: const Text('備註', style: TextStyle(fontSize: 14)),
                selected: selectedType == MemoType.note,
                onSelected: (_) => onTypeChanged(MemoType.note),
              ),
              FilterChip(
                label: const Text('待辦', style: TextStyle(fontSize: 14)),
                selected: selectedType == MemoType.todo,
                onSelected: (_) => onTypeChanged(MemoType.todo),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              FilterChip(
                label: const Text('全部狀態', style: TextStyle(fontSize: 14)),
                selected: selectedCompleted == null,
                onSelected: (_) => onCompletedChanged(null),
              ),
              FilterChip(
                label: const Text('完成', style: TextStyle(fontSize: 14)),
                selected: selectedCompleted == true,
                onSelected: (_) => onCompletedChanged(true),
              ),
              FilterChip(
                label: const Text('未完成', style: TextStyle(fontSize: 14)),
                selected: selectedCompleted == false,
                onSelected: (_) => onCompletedChanged(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
