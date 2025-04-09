import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/core/utils/dialog_util.dart';
import 'package:smartplanner/core/utils/util.dart';
import 'package:smartplanner/models/enum.dart';
import 'package:smartplanner/models/hashtag.dart';
import 'package:smartplanner/providers/hashtag_provider.dart';

/// HashtagManagePage：管理 Hashtag 的頁面
class HashtagManagePage extends ConsumerStatefulWidget {
  const HashtagManagePage({super.key});

  @override
  ConsumerState<HashtagManagePage> createState() => _HashtagManagePageState();
}

class _HashtagManagePageState extends ConsumerState<HashtagManagePage> {
  final Map<HashtagCategory, bool> _expanded = {};
  final Set<String> _selectedIds = {};
  final TextEditingController _inputController = TextEditingController();
  String _input = '';

  @override
  void initState() {
    super.initState();
    for (var cat in HashtagCategory.values) {
      _expanded[cat] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(hashtagProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIds.isEmpty ? 'Hashtag' : 'Hashtag (${_selectedIds.length})'),
        centerTitle: true,
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showConfirmDeleteDialog(
                  context,
                  message: '確認要刪除 ${_selectedIds.length} 個 Hashtag 嗎？',
                );
                if (confirm) {
                  ref.read(hashtagProvider.notifier).deleteHashtags(_selectedIds.toList());
                  setState(() => _selectedIds.clear());
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: '新增 Hashtag',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) => setState(() => _input = value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed:
                      _input.trim().isEmpty
                          ? null
                          : () {
                            final tag = Hashtag(
                              id: generateId(),
                              name: _input.trim(),
                              category: _randomCategory(), //  TODO: 後續接 AI
                              source: _randomSource(), //TODO: 改回 HashtagSource.manual,
                            );

                            ref.read(hashtagProvider.notifier).addHashtag(tag);
                            _inputController.clear();
                            setState(() => _input = '');
                          },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children:
                  HashtagCategory.values.map((cat) {
                    final tags = allTags.where((h) => h.category == cat).toList();
                    if (tags.isEmpty) return const SizedBox();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4), // 🔹 加入分類間距
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _expanded[cat] = !_expanded[cat]!),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getCategoryLabel(cat),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Icon(_expanded[cat]! ? Icons.expand_less : Icons.expand_more),
                                ],
                              ),
                            ),
                          ),
                          if (_expanded[cat]!)
                            ...tags.map((tag) {
                              final selected = _selectedIds.contains(tag.id);
                              final isAi = tag.source == HashtagSource.aiGenerated;

                              return Container(
                                color:
                                    selected
                                        ? Colors.blue.shade50
                                        : isAi
                                        ? const Color(0xFFB0BEC5) // 鐵灰（AI）
                                        : const Color(0xFFFFF9C4), // 黃膚（手動）
                                child: ListTile(
                                  title: Text(tag.name),
                                  trailing: selected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                                  onLongPress: () {
                                    setState(() {
                                      _selectedIds.contains(tag.id)
                                          ? _selectedIds.remove(tag.id)
                                          : _selectedIds.add(tag.id);
                                    });
                                  },
                                  onTap: () {
                                    if (_selectedIds.isNotEmpty) {
                                      setState(() {
                                        _selectedIds.contains(tag.id)
                                            ? _selectedIds.remove(tag.id)
                                            : _selectedIds.add(tag.id);
                                      });
                                    }
                                  },
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(HashtagCategory category) {
    switch (category) {
      case HashtagCategory.noun:
        return '名詞';
      case HashtagCategory.verb:
        return '動詞';
      case HashtagCategory.adjective:
        return '形容詞';
      case HashtagCategory.subject:
        return '主詞';
      case HashtagCategory.object:
        return '受詞';
      default:
        return '未分類';
    }
  }

  /// ⚠️ 暫用：產生隨機分類（未來用 AI 取代）
  HashtagCategory _randomCategory() {
    final values = HashtagCategory.values;
    return values[Random().nextInt(values.length)];
  }

  /// ⚠️ 暫用：產生隨機分類（未來用 AI 取代）
  HashtagSource _randomSource() {
    final values = HashtagSource.values;
    return values[Random().nextInt(values.length)];
  }
}
