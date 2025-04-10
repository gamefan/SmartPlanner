import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartplanner/models/hashtag.dart';
import 'package:smartplanner/models/memo_item.dart';

/// 提供儲存與讀取的本地儲存服務
class StorageService {
  static const String memoKey = 'memo_items';
  static const String hashtagKey = 'hashtags';
  static const String apiKey = 'openai_api_key';

  /// 儲存 Memo 清單至 SharedPreferences
  Future<void> saveMemos(List<MemoItem> memos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = memos.map((item) => item.toJson()).toList();
    await prefs.setString(memoKey, jsonEncode(jsonList));
  }

  /// 載入 Memo 清單，若無則回傳空清單
  Future<List<MemoItem>> loadMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(memoKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => MemoItem.fromJson(json)).toList();
  }

  /// 儲存 Hashtag 清單至 SharedPreferences
  Future<void> saveHashtags(List<Hashtag> hashtags) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = hashtags.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(hashtagKey, jsonList);
  }

  /// 載入 Hashtag 清單，若無則回傳空清單
  Future<List<Hashtag>> loadHashtags() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(hashtagKey) ?? [];
    return jsonList.map((e) => Hashtag.fromJson(json.decode(e))).toList();
  }

  /// 儲存 OpenAI API Key
  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiKey, key);
  }

  /// 讀取 OpenAI API Key（若無則回傳 null）
  Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(apiKey);
  }
}
