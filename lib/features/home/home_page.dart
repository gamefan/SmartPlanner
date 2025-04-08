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

    return Scaffold(
      appBar: state.isBottomExpanded ? null : AppBar(title: const Text('Smart Planner'), centerTitle: true),

      body: SafeArea(
        child: GestureDetector(
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
            children: [
              Column(
                children: [
                  // 上方月曆或日期區塊
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
                                    color: Color(0xFFFFEBEE), // 淺粉紅
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)), // 加圓角
                                  ),
                                  headerMargin: EdgeInsets.symmetric(vertical: 4), // 外距
                                  headerPadding: EdgeInsets.symmetric(vertical: 2), // 內距，控制高度用
                                ),

                                calendarStyle: const CalendarStyle(
                                  todayDecoration: BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle),
                                  todayTextStyle: TextStyle(
                                    color: Colors.black87, // 深灰
                                    fontWeight: FontWeight.w500, // 微粗一點
                                  ),
                                  selectedDecoration: BoxDecoration(color: Color(0xFFBBDEFB), shape: BoxShape.circle),
                                  selectedTextStyle: TextStyle(
                                    color: Color(0xFF212121), // 深灰
                                    fontWeight: FontWeight.w500, // 微粗一點
                                  ),
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
                      child: Column(
                        children: const [
                          MemoInputSection(),
                          SizedBox(height: 12),
                          Expanded(child: SingleChildScrollView(child: MemoListSection())),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 疊在右上角的小按鈕（只有展開狀態才出現）
              if (state.isBottomExpanded)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, right: 6),
                    child: FloatingActionButton.small(
                      heroTag: 'menu',
                      onPressed: () {
                        // TODO: 開啟功能選單
                      },
                      child: const Icon(Icons.menu),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
