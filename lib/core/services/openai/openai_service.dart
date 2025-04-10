/*
 功能重點：
讀取儲存在 StorageService 的 API Key
發送 POST 請求到 https://api.openai.com/v1/chat/completions
使用 GPT-3.5 或 4 的 chat 模式
接收回傳並處理 JSON，未來可透過 parser 拆解（這部分會交給 openai_response_parser.dart）
 */

import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:smartplanner/core/services/storage_service.dart';

class OpenAiService {
  static const _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// 呼叫 GPT 進行自然語言分析
  /// [prompt]：完整提示語
  /// [model]：可用 'gpt-3.5-turbo' 或 'gpt-4'
  static Future<String?> sendPrompt({required String prompt, String model = 'gpt-4o'}) async {
    final apiKey = await StorageService().loadApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('尚未設定 OpenAI API Key');
    }

    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': '你是個語意理解助手，會根據使用者輸入分析關鍵結構並輸出 JSON。'},
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.2,
    });

    final response = await http.post(Uri.parse(_apiUrl), headers: headers, body: body);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      var text = json['choices'][0]['message']['content'];
      // 去除 GPT 加上的 ```json 與 ``` 標記
      text = text.trim();
      if (text.startsWith('```json')) {
        text = text.replaceFirst('```json', '').trim();
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3).trim();
      }

      return text;
    } else {
      print('OpenAI API 錯誤：${response.statusCode} ${response.body}');
      Fluttertoast.showToast(
        msg: 'OpenAI API 錯誤：${response.statusCode} ${response.body}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return null;
    }
  }
}
