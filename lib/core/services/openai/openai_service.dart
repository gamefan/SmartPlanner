/*
 功能重點：
讀取儲存在 StorageService 的 API Key
發送 POST 請求到 https://api.openai.com/v1/chat/completions
使用 GPT-4o + Assistants API 的 chat 模式
接收回傳並處理 JSON，未來可透過 parser 拆解（這部分會交給 openai_response_parser.dart）
 */

import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:smartplanner/core/services/openai/openai_assistant.dart';
import 'package:smartplanner/core/services/storage_service.dart';

class OpenAiService {
  static const _threadRunUrl = 'https://api.openai.com/v1/threads';
  static const _assistantId = 'asst_KBaAt2sFFEVCDYgwQsxYl9AP';

  /// 發送訊息至 Assistant API 並建立 Run（會自動建立 threadId 並儲存）
  static Future<String?> sendToAssistant({required String message}) async {
    final apiKey = await StorageService().loadApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('尚未設定 OpenAI API Key');
    }

    final threadId = await OpenAIAssistantService.getOrCreateThreadId(apiKey);
    if (threadId == null) return null;

    // 建立一則訊息在指定 Thread 中
    final messageResponse = await http.post(
      Uri.parse('$_threadRunUrl/$threadId/messages'),
      headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json', 'OpenAI-Beta': 'assistants=v2'},
      body: jsonEncode({'role': 'user', 'content': message}),
    );

    if (messageResponse.statusCode != 200) {
      Fluttertoast.showToast(
        msg: '建立訊息失敗：${messageResponse.statusCode}\n${messageResponse.body}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return null;
    }

    // 建立 Run
    final runResponse = await http.post(
      Uri.parse('$_threadRunUrl/$threadId/runs'),
      headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json', 'OpenAI-Beta': 'assistants=v2'},
      body: jsonEncode({'assistant_id': _assistantId}),
    );

    if (runResponse.statusCode != 200) {
      final errMsg = '建立 Run 失敗：${runResponse.statusCode}\n${runResponse.body}';
      print('❌ $errMsg');
      Fluttertoast.showToast(msg: errMsg, toastLength: Toast.LENGTH_LONG);
      return null;
    }

    final runId = jsonDecode(runResponse.body)['id'];
    return runId;
  }

  /// 輪詢 Run 狀態，直到完成後取得結果
  static Future<String?> pollRunAndGetResult(String runId) async {
    final apiKey = await StorageService().loadApiKey();
    final threadId = await OpenAIAssistantService.getOrCreateThreadId(apiKey!);

    // 輪詢直到 run status == completed
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final res = await http.get(
        Uri.parse('https://api.openai.com/v1/threads/$threadId/runs/$runId'),
        headers: {'Authorization': 'Bearer $apiKey', 'OpenAI-Beta': 'assistants=v2'},
      );
      final json = jsonDecode(res.body);
      if (json['status'] == 'completed') break;
    }

    // 取得回覆訊息
    final msgRes = await http.get(
      Uri.parse('https://api.openai.com/v1/threads/$threadId/messages'),
      headers: {'Authorization': 'Bearer $apiKey', 'OpenAI-Beta': 'assistants=v2'},
    );

    final data = jsonDecode(msgRes.body)['data'];
    final aiMsg = data.firstWhere((msg) => msg['role'] == 'assistant', orElse: () => null);
    if (aiMsg == null) return null;

    var text = aiMsg['content'][0]['text']['value'].trim();
    if (text.startsWith('```json')) {
      text = text.replaceFirst('```json', '').trim();
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3).trim();
    }
    return text;
  }
}
