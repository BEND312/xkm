import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/entity/duifene/duifene_course.dart';
import 'package:swustmeow/entity/duifene/duifene_test.dart';
import 'package:swustmeow/entity/duifene/duifene_test_base.dart';
import 'package:swustmeow/utils/time.dart';

import '../../data/m_theme.dart';
import '../../services/global_service.dart';
import '../../utils/status.dart';

class DuiFenEHomeworkPage extends StatefulWidget {
  const DuiFenEHomeworkPage({super.key});

  @override
  State<StatefulWidget> createState() => _DuiFenEHomeworkPageState();
}

class _DuiFenEHomeworkPageState extends State<DuiFenEHomeworkPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  late bool _isLogin;
  late FPopoverController _selectDisplayModeController;
  Map<DuiFenECourse, List<DuiFenETestBase>> _allTests = {};
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _isLogin = GlobalService.duifeneService?.isLogin == true;
    if (_isLogin) {
      _load().then((_) => _refresh(() => _isLoading = false));
    } else {
      _isLoading = false;
    }
    _selectDisplayModeController = FPopoverController(vsync: this);
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _selectDisplayModeController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final courses = GlobalService.duifeneCourses.value;
    Map<DuiFenECourse, List<DuiFenETestBase>> result = {};

    for (final course in courses) {
      List<DuiFenETestBase> allTests = [];

      // 获取在线测试
      final testsResult =
          await GlobalService.duifeneService?.getTests(course);
      if (testsResult?.status == Status.ok) {
        allTests.addAll(testsResult!.value!);
      }

      // 获取作业
      final homeworksResult =
          await GlobalService.duifeneService?.getHomeworks(course);
      if (homeworksResult?.status == Status.ok) {
        allTests.addAll(homeworksResult!.value!);
      }

      if (allTests.isNotEmpty) {
        result[course] = allTests;
      }
    }

    _refresh(() => _allTests = result);
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(
        title: '对分易作业',
        suffixIcons: [
          RefreshIcon(
            isRefreshing: _isRefreshing,
            onRefresh: () async {
              if (!_isLogin || _isLoading || _isRefreshing) return;
              _refresh(() {
                _isRefreshing = true;
              });
              _refreshAnimationController.repeat();
              await GlobalService.loadDuiFenECourses();
              await _load();
              _refresh(() {
                _isRefreshing = false;
                _refreshAnimationController.stop();
                _refreshAnimationController.reset();
              });
            },
          ),
        ],
      ),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(MTheme.radius),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: MTheme.primary2),
      );
    }

    if (_allTests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.clipboardList,
              size: 60,
              color: Colors.grey.withValues(alpha: 0.6),
            ),
            SizedBox(height: 16),
            Text(
              '这里什么都木有~',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                '暂无对分易作业或测试数据，请点击右上角刷新按钮重试',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                if (!_isLogin || _isLoading || _isRefreshing) return;
                _refresh(() {
                  _isRefreshing = true;
                });
                _refreshAnimationController.repeat();
                await GlobalService.loadDuiFenECourses();
                await _load();
                _refresh(() {
                  _isRefreshing = false;
                  _refreshAnimationController.stop();
                  _refreshAnimationController.reset();
                });
              },
              icon: FaIcon(
                FontAwesomeIcons.arrowsRotate,
                size: 16,
                color: MTheme.primary2,
              ),
              label: Text('刷新数据'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MTheme.primary2,
              ),
            ),
          ],
        ),
      );
    }

    return FTabs(
      scrollable: true,
      onPress: (index) {},
      tabs: _allTests.keys.map((course) {
        return FTabEntry(
          label: Text(course.courseName),
          content: Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [_buildCourseTestsList(_allTests[course]!)],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseTestsList(List<DuiFenETestBase> tests) {
    // 按日期分组
    final groupedTests = <DateTime, List<DuiFenETestBase>>{};
    for (var test in tests) {
      final date =
          DateTime(test.endTime.year, test.endTime.month, test.endTime.day);
      groupedTests.putIfAbsent(date, () => []).add(test);
    }

    // 修改这里：将日期倒序排序
    final sortedDates = groupedTests.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 改为b.compareTo(a)实现倒序

    return Column(
      children: sortedDates.map((date) {
        final dayTests = groupedTests[date]!;
        // 对同一天的作业也按结束时间倒序排序
        dayTests.sort((a, b) => b.endTime.compareTo(a.endTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...dayTests.map((test) => _buildTestCard(test)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTestCard(DuiFenETestBase test) {
    final now = DateTime.now();
    final isExpired = now > test.endTime;
    final isTest = test is DuiFenETest;

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.grey
                      : isTest
                          ? Colors.blue
                          : Colors.green,
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              test.name.trim(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          _buildStatusBadge(test.finished, isExpired),
                        ],
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildBadge(
                            isTest ? '在线测试' : '作业',
                            color: isTest ? Colors.blue : Colors.green,
                          ),
                          _buildBadge(
                            '结束：${_formatDateTime(test.endTime)}',
                            color: Colors.grey,
                          ),
                          if (isTest && test.limitMinutes != 0) ...[
                            _buildBadge(
                              '限时：${test.limitMinutes}分钟',
                              color: Colors.orange,
                            ),
                            if (test.finished)
                              _buildBadge(
                                '得分：${test.score}',
                                color: Colors.purple,
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, {required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool finished, bool expired) {
    return _buildBadge(
      finished ? '已完成' : '未完成',
      color: finished
          ? Colors.green
          : expired
              ? Colors.red
              : Colors.orange,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    final tomorrow = now.add(Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '今天';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return '昨天';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return '明天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month.padL2}/${dateTime.day.padL2} ${dateTime.hour.padL2}:${dateTime.minute.padL2}';
  }
}
