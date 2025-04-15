import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartplanner/core/services/storage_service.dart';

class OpenAIAssistantService {
  static const String _threadEndpoint = 'https://api.openai.com/v1/threads';
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'OpenAI-Beta': 'assistants=v2',
  };

  /// 建立 Thread，成功則回傳 threadId，失敗回傳 null
  static Future<String?> createThread(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse(_threadEndpoint),
        headers: {..._defaultHeaders, 'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode == 200) {
        final threadId = jsonDecode(response.body)['id'];
        await StorageService().saveAssistantThreadId(threadId);
        return threadId;
      } else {
        print('❌ 建立 Thread 失敗（status=${response.statusCode}）：${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 建立 Thread 例外錯誤：$e');
      return null;
    }
  }

  /// 取得已儲存的 Thread ID，若無則自動建立一組
  static Future<String?> getOrCreateThreadId(String apiKey) async {
    final storage = StorageService();
    final saved = await storage.loadAssistantThreadId();
    if (saved != null) return saved;
    return await createThread(apiKey);
  }
}
