import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smartplanner/core/services/speech_input_service.dart';

void showVoiceInputDialog(BuildContext context, {required Function(String text) onResult}) {
  final speechService = SpeechInputService();
  String recognizedText = '';
  bool hasSpoken = false;
  bool isRecording = false; // ✅ 提出來避免 dead code 判斷錯誤

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0x88000000), // ✅ 改為準確透明黑色
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pop(); // 點擊背景 ➜ 關閉
            },
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color:
                        isRecording
                            ? const Color(0xB3000000) // 錄音中更深色
                            : const Color(0x88000000),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isRecording) ...[
                            const Text('🎤 正在錄音中，請說話⋯⋯', style: TextStyle(color: Colors.white, fontSize: 16)),
                            const SizedBox(height: 12),
                            const _RecordingIndicator(),
                            const SizedBox(height: 20),
                          ],
                          Listener(
                            onPointerDown: (_) async {
                              print('🎤 開始初始化錄音...');
                              setState(() => isRecording = true);
                              await speechService.init();
                              print('✅ 語音服務初始化完成');
                              await speechService.startListening(
                                onResult: (text) {
                                  print('📝 辨識文字結果：$text');
                                  recognizedText = text;
                                  hasSpoken = true;
                                },
                                localeId: 'zh-TW',
                              );
                              print('🎤 開始錄音中...');
                            },
                            onPointerUp: (_) async {
                              print('🛑 停止錄音');
                              await speechService.stopListening();

                              // 等待語音結果吐出來
                              await Future.delayed(const Duration(milliseconds: 300));

                              if (hasSpoken && recognizedText.trim().isNotEmpty) {
                                print('✅ 回傳最終文字：$recognizedText');
                                onResult(recognizedText.trim());
                              } else {
                                print('⚠️ 沒有辨識到任何語音輸入');
                                Fluttertoast.showToast(
                                  msg: '沒有辨識到任何語音輸入',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              }
                              if (context.mounted) {
                                Navigator.maybePop(context); // ✅ 使用 maybePop 避免錯誤
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                              ),
                              child: const Icon(Icons.mic, color: Colors.white, size: 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// 錄音中動畫圈圈
class _RecordingIndicator extends StatefulWidget {
  const _RecordingIndicator({super.key});

  @override
  State<_RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<_RecordingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
      ),
    );
  }
}
