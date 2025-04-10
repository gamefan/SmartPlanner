import 'package:speech_to_text/speech_to_text.dart';

class SpeechInputService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  /// 初始化語音辨識服務
  Future<bool> init() async {
    _isInitialized = await _speech.initialize();
    return _isInitialized;
  }

  /// 開始語音辨識
  Future<void> startListening({required Function(String) onResult, String localeId = 'zh-TW'}) async {
    if (!_isInitialized) await init();

    if (_isInitialized) {
      _speech.listen(
        onResult: (result) => onResult(result.recognizedWords),
        localeId: localeId,
        listenFor: const Duration(seconds: 30), // ✅ 最長錄音時間
        pauseFor: const Duration(seconds: 30), // ✅ 最久沉默才會停
      );
    }
  }

  /// 停止語音辨識
  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
