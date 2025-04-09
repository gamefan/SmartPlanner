/*
使用 Riverpod	管理狀態（已使用 ViewModel）
預設畫面為 HomePage	你目前主要操作畫面
加上初始化流程	含 memoProvider.init() 啟動時載入本地資料
 */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/features/hashtags/hashtag_manager_page.dart';
import 'package:smartplanner/features/home/home_page.dart';
import 'package:smartplanner/features/memo/all_memo_page.dart';
import 'package:smartplanner/providers/memo_provider.dart';

/// App 入口點
void main() {
  runApp(const ProviderScope(child: MyApp()));
}

/// 應用程式根元件
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化時讀取本地儲存的資料
    ref.read(memoProvider.notifier).init();

    return MaterialApp(
      title: 'Smart Planner',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {'/allMemos': (_) => const AllMemoPage(), '/hashtagManage': (context) => const HashtagManagePage()},
    );
  }
}
