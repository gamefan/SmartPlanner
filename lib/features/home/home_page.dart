/*
月曆區塊	顯示上方日曆（未來加動畫）
輸入區	使用 MemoInputSection
清單區	使用 MemoListSection
滿版切換邏輯	根據 isBottomExpanded 決定區塊顯示方式
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartplanner/features/home/home_view_model.dart';
import 'package:smartplanner/features/home/widgets/memo_input_section.dart';
import 'package:smartplanner/features/home/widgets/memo_list_section.dart';
import 'package:table_calendar/table_calendar.dart';

/// 首頁畫面：整合月曆 + 輸入 + 清單功能
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    /// 根據鍵盤狀態決定是否顯示輸入框
    final isFloating = state.isKeyboardFloating;

    return Scaffold(
      endDrawer: _buildDrawer(context),
      appBar:
          state.isBottomExpanded
              ? null
              : AppBar(
                title: const Text('Smart Planner'),
                centerTitle: true,
                actions: [
                  Builder(
                    builder:
                        (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                        ),
                  ),
                ],
              ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus(); // 點空白區自動取消輸入
          },
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta != null) {
              if (details.primaryDelta! < -10) {
                viewModel.setBottomExpanded(true); // 上滑展開下方
              } else if (details.primaryDelta! > 10) {
                viewModel.setBottomExpanded(false); // 下滑還原
              }
            }
          },
          child: Stack(
            fit: StackFit.expand, // 讓整個畫面能當作定位基準
            children: [
              Column(
                children: [
                  // 上方月曆區塊（你的原樣式）
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SizeTransition(sizeFactor: animation, axisAlignment: -1.0, child: child),
                      );
                    },
                    child:
                        state.isBottomExpanded
                            ? Container(
                              key: const ValueKey('collapsed'),
                              height: 60,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed:
                                        () =>
                                            viewModel.selectDate(state.selectedDate.subtract(const Duration(days: 1))),
                                  ),
                                  Text(
                                    '${state.selectedDate.year}/${state.selectedDate.month}/${state.selectedDate.day}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed:
                                        () => viewModel.selectDate(state.selectedDate.add(const Duration(days: 1))),
                                  ),
                                ],
                              ),
                            )
                            : Container(
                              key: const ValueKey('expanded'),
                              color: const Color(0xFFF8F9FA),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: TableCalendar(
                                focusedDay: state.selectedDate,
                                firstDay: DateTime(2020, 1, 1),
                                lastDay: DateTime(2030, 12, 31),
                                selectedDayPredicate: (day) => isSameDay(day, state.selectedDate),
                                onDaySelected: (selected, focused) {
                                  viewModel.selectDate(selected);
                                },
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                  ),
                                  headerMargin: EdgeInsets.symmetric(vertical: 4),
                                  headerPadding: EdgeInsets.symmetric(vertical: 2),
                                ),
                                calendarStyle: const CalendarStyle(
                                  todayDecoration: BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle),
                                  todayTextStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                  selectedDecoration: BoxDecoration(color: Color(0xFFBBDEFB), shape: BoxShape.circle),
                                  selectedTextStyle: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                  ),

                  // 下方內容區
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius:
                            state.isBottomExpanded
                                ? const BorderRadius.vertical(top: Radius.circular(16))
                                : BorderRadius.zero,
                      ),
                      child: const SingleChildScrollView(child: MemoListSection()),
                    ),
                  ),
                ],
              ),

              // 輸入框位置 顯示邏輯
              Positioned(
                left: 12,
                right: 12,
                bottom: state.isKeyboardFloating ? MediaQuery.of(context).padding.bottom + 10 : 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: state.isKeyboardFloating ? Color(0xFFE6E6E6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow:
                        state.isKeyboardFloating
                            ? [
                              BoxShadow(
                                color: Colors.black26, // 黑 26%（比 black12 更深一點）
                                blurRadius: 120, // ✅ 模糊範圍擴大
                                spreadRadius: 4, // ✅ 陰影範圍微微擴張
                                offset: Offset(0, 4), // ✅ 陰影更往下飄)
                              ),
                            ]
                            : null,
                  ),
                  child: SafeArea(child: MemoInputSection()),
                ),
              ),

              // 右上角浮動按鈕（不變）
              if (state.isBottomExpanded)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, right: 6),
                    child: Builder(
                      builder:
                          (context) => FloatingActionButton.small(
                            heroTag: 'menu',
                            onPressed: () => Scaffold.of(context).openEndDrawer(),
                            child: const Icon(Icons.menu),
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立側邊選單（Drawer）
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 40,
              color: const Color(0xFFBBDEFB),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('選單', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            ListTile(
              leading: const Icon(Icons.view_list),
              title: const Text('所有記事'),
              onTap: () {
                Navigator.pop(context); // 關閉 Drawer
                Navigator.pushNamed(context, '/allMemos');
              },
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Hashtag 管理'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/hashtagManage');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Setting 設定'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            // 可擴充更多功能
          ],
        ),
      ),
    );
  }
}
