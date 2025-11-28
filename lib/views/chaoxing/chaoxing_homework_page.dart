import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/chaoxing/chaoxing_course_info_card.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/entity/chaoxing/chaoxing_course.dart';
import 'package:swustmeow/entity/chaoxing/chaoxing_homework.dart';

import '../../data/m_theme.dart';
import '../../services/global_service.dart';
import '../../utils/status.dart';

class ChaoXingHomeworkPage extends StatefulWidget {
  const ChaoXingHomeworkPage({super.key});

  @override
  State<StatefulWidget> createState() => _ChaoXingHomeworkPageState();
}

class _ChaoXingHomeworkPageState extends State<ChaoXingHomeworkPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  late bool _isLogin;
  late FPopoverController _selectDisplayModeController;
  Map<ChaoXingCourse, List<ChaoXingHomework>> _allHomeworks = {};
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();

    _isLogin = GlobalService.chaoXingService?.isLogin == true;
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
    Map<ChaoXingCourse, List<ChaoXingHomework>> result = {};

    // 获取课程列表
    final coursesResult = await GlobalService.chaoXingService?.getCourseList();
    final courses = coursesResult?.status == Status.ok
        ? coursesResult!.value as List<ChaoXingCourse>
        : [];

    for (final course in courses) {
      // 获取每个课程的作业
      final homeworksResult =
          await GlobalService.chaoXingService?.getHomeworks(course);

      if (homeworksResult?.status == Status.ok) {
        List<ChaoXingHomework> homeworks =
            (homeworksResult!.value as List<dynamic>).cast();
        if (homeworks.isNotEmpty) {
          result[course] = homeworks;
        }
      }
    }

    _refresh(() => _allHomeworks = result);
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
        title: '学习通作业',
        suffixIcons: [
          RefreshIcon(
            isRefreshing: _isRefreshing,
            onRefresh: () async {
              if (!_isLogin || _isLoading || _isRefreshing) return;
              _refresh(() {
                _isRefreshing = true;
              });
              _refreshAnimationController.repeat();
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: MTheme.primary2),
            SizedBox(height: 16),
            Text(
              '正在加载学习通作业...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_allHomeworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.bookOpen,
              size: 60,
              color: Colors.blue.withValues(alpha: 0.6),
            ),
            SizedBox(height: 16),
            Text(
              '这里没有作业~',
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
                '暂无学习通作业数据，请点击右上角刷新按钮重试',
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
                color: Colors.blue,
              ),
              label: Text('刷新数据'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      );
    }

    return FTabs(
      scrollable: true,
      onPress: (index) {},
      tabs: _allHomeworks.keys.map((course) {
        return FTabEntry(
          label: Text(
            course.courseName,
            style: TextStyle(fontSize: 14),
          ),
          content: Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                ChaoXingCourseInfoCard(
                  course: course,
                  totalCount: _allHomeworks[course]!.length,
                  type: '作业',
                ),
                _buildCourseHomeworkList(_allHomeworks[course]!),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseHomeworkList(List<ChaoXingHomework> homeworks) {
    // 按状态分组（未提交的优先显示）
    final pendingHomeworks =
        homeworks.where((h) => h.status.contains('未交')).toList();
    final completedHomeworks =
        homeworks.where((h) => !h.status.contains('未交')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pendingHomeworks.isNotEmpty) ...[
          _buildHomeworkGroupHeader(
              '待完成', FontAwesomeIcons.hourglassHalf, Colors.orange),
          ...pendingHomeworks
              .map((hw) => _buildHomeworkCard(hw, isPending: true)),
          SizedBox(height: 16),
        ],
        if (completedHomeworks.isNotEmpty) ...[
          _buildHomeworkGroupHeader(
              '已完成', FontAwesomeIcons.check, Colors.green),
          ...completedHomeworks
              .map((hw) => _buildHomeworkCard(hw, isPending: false)),
        ],
      ],
    );
  }

  Widget _buildHomeworkGroupHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          FaIcon(
            icon,
            size: 14,
            color: color,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(
    ChaoXingHomework homework, {
    required bool isPending,
  }) {
    final Color statusColor = isPending ? Colors.orange : Colors.green;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
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
                            homework.title.trim(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _buildStatusBadge(homework.status),
                      ],
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...homework.labels.map((label) =>
                            _buildBadge(label, color: Colors.blue.shade700)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _buildStatusBadge(String status) {
    final bool isComplete = !status.contains('未交');
    final Color color = isComplete ? Colors.green : Colors.orange;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
