import 'package:flutter/material.dart';
import 'package:smartplanner/core/services/storage_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSavedKey();
  }

  Future<void> _loadSavedKey() async {
    final saved = await _storage.loadApiKey();
    setState(() {
      _savedKey = saved;
      _controller.text = saved ?? '';
    });
  }

  Future<void> _saveKey() async {
    setState(() => _isSaving = true);
    await _storage.saveApiKey(_controller.text.trim());
    setState(() => _isSaving = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key 已儲存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('輸入 OpenAI API Key'),
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
          ],
        ),
      ),
    );
  }
}
