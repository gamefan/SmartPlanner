import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartplanner/core/services/notification_service.dart';
import 'package:smartplanner/core/services/openai/openai_assistant.dart';
import 'package:smartplanner/core/services/storage_service.dart';
import 'package:smartplanner/core/utils/util.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _controller = TextEditingController();
  final StorageService _storage = StorageService();

  String? _savedKey;
  bool _isSaving = false;

  int _earliestHour = 8;
  int _latestHour = 22;
  String _outOfRangeBehavior = 'skip';

  @override
  void initState() {
    super.initState();
    _loadSavedKey();
    _loadNotificationSettings();
  }

  /// 載入 API Key
  Future<void> _loadSavedKey() async {
    final saved = await _storage.loadApiKey();
    setState(() {
      _savedKey = saved;
      _controller.text = saved ?? '';
    });
  }

  /// 儲存 API Key
  Future<void> _saveKey() async {
    setState(() => _isSaving = true);
    await _storage.saveApiKey(_controller.text.trim());
    setState(() => _isSaving = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key 已儲存')));
    }
  }

  /// 初始 通知時間相關設定
  Future<void> _loadNotificationSettings() async {
    _earliestHour = await _storage.loadEarliestHour() ?? 8;
    _latestHour = await _storage.loadLatestHour() ?? 22;
    _outOfRangeBehavior = await _storage.loadOutOfRangeBehavior() ?? 'skip';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // API Key 設定
            const Text('OpenAI API Key設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'sk-xxxxxxxxxxxxxxxxxxxxxxxx'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveKey,
              icon: const Icon(Icons.save),
              label: const Text('儲存 API Key'),
            ),
            if (_savedKey != null) ...[
              const SizedBox(height: 20),
              const Text('目前已儲存的 Key：'),
              Text('••••••••••••••••••', style: TextStyle(color: Colors.grey.shade600)),
            ],

            //  建立 Assistant Thread
            const SizedBox(height: 20),
            const Text('Assistant Thread', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.link),
              title: FutureBuilder<String?>(
                future: _storage.loadAssistantThreadId(),
                builder: (context, snapshot) {
                  final id = snapshot.data;
                  return Text(
                    id != null ? '目前 Assistant Thread ID：$id' : '尚未建立 Assistant Thread ID',
                    style: const TextStyle(fontSize: 14),
                  );
                },
              ),
              subtitle: TextButton(
                onPressed: () async {
                  final apiKey = await _storage.loadApiKey();
                  if (apiKey == null || apiKey.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ 尚未設定 API Key')));
                    return;
                  }
                  final newId = await OpenAIAssistantService.createThread(apiKey);

                  if (context.mounted) {
                    if (newId != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ 已重建 Thread：$newId')));
                      setState(() {}); // 更新 UI
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ 建立 Thread 失敗')));
                    }
                  }
                },
                child: const Text('重新建立 Thread'),
              ),
            ),

            // 通知時間設定
            const SizedBox(height: 20),
            const Text('通知時間範圍設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),
            Row(
              children: [
                const Text('最早通知時間：'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _earliestHour,
                  items: List.generate(24, (index) {
                    return DropdownMenuItem(value: index, child: Text('$index:00'));
                  }),
                  onChanged: (value) async {
                    if (value != null) {
                      await _storage.saveEarliestHour(value);
                      setState(() => _earliestHour = value);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                const Text('最晚通知時間：'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _latestHour,
                  items: List.generate(24, (index) {
                    return DropdownMenuItem(value: index, child: Text('$index:00'));
                  }),
                  onChanged: (value) async {
                    if (value != null) {
                      await _storage.saveLatestHour(value);
                      setState(() => _latestHour = value);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Text('超出範圍處理方式：'),
            RadioListTile<String>(
              title: const Text('不建立通知'),
              value: 'skip',
              groupValue: _outOfRangeBehavior,
              onChanged: (value) async {
                if (value != null) {
                  await _storage.saveOutOfRangeBehavior(value);
                  setState(() => _outOfRangeBehavior = value);
                }
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              title: const Text('調整為最早／最晚'),
              value: 'adjust',
              groupValue: _outOfRangeBehavior,
              onChanged: (value) async {
                if (value != null) {
                  await _storage.saveOutOfRangeBehavior(value);
                  setState(() => _outOfRangeBehavior = value);
                }
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),

            // 通知功能測試
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('通知功能測試', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Icon(Icons.notifications),
              ],
            ),
            // 通知功能測試
            ListTile(
              subtitle: Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      try {
                        final testTime = DateTime.now().add(const Duration(seconds: 5));
                        await NotificationService.scheduleNotification(
                          id: 999,
                          title: '測試通知',
                          body: '這是一筆 10 秒後的測試通知',
                          scheduledTime: testTime,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('測試訊息 (10 秒後 通知）')));
                      } catch (e, stack) {
                        print('❌ 通知建立失敗：$e');
                        print(stack);
                        // 在 catch 區塊中加上這行，複製錯誤訊息
                        await Clipboard.setData(ClipboardData(text: e.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 建立通知失敗：$e')));
                      }
                    },
                    child: const Text('測試通知'),
                  ),

                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final status = await Permission.notification.status;
                      if (status.isDenied || status.isPermanentlyDenied) {
                        final result = await Permission.notification.request();
                        final msg = result.isGranted ? '✅ 通知權限已授權' : '❌ 通知權限被拒絕';
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔔 通知權限已存在')));
                      }
                    },
                    child: const Text('請求權限'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: openExactAlarmSettings, child: const Text('精確權限')),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('目前等待中的通知'),
              onTap: () async {
                final pending = await NotificationService.getPendingNotifications();
                final allMemos = await StorageService().loadMemos();

                if (pending.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📭 沒有等待中的通知')));
                } else {
                  showDialog(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: const Text('等待中的通知'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: pending.length,
                              itemBuilder: (context, index) {
                                final p = pending[index];

                                final matchedMemo = allMemos.firstWhereOrNull(
                                  (m) =>
                                      m.notificationId == p.id &&
                                      m.notificationTime != null &&
                                      m.notificationTime!.isAfter(DateTime.now()),
                                );

                                final displayTime =
                                    matchedMemo?.notificationTime?.toLocal().toString().substring(0, 16) ?? '未知時間';

                                return ListTile(
                                  title: Text(p.title ?? '（無標題）'),
                                  subtitle: Text('ID: ${p.id}｜內容：${p.body ?? '（無內容）'}\n通知時間：$displayTime'),
                                );
                              },
                            ),
                          ),
                          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('關閉'))],
                        ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
