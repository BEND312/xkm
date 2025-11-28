import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/entity/chaoxing/chaoxing_course.dart';
import 'package:swustmeow/entity/chaoxing/chaoxing_exam.dart';

import '../../components/chaoxing/chaoxing_course_info_card.dart';
import '../../data/m_theme.dart';
import '../../services/global_service.dart';
import '../../utils/status.dart';

class ChaoXingExamsPage extends StatefulWidget {
  const ChaoXingExamsPage({super.key});

  @override
  State<StatefulWidget> createState() => _ChaoXingExamsPageState();
}

class _ChaoXingExamsPageState extends State<ChaoXingExamsPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  late bool _isLogin;
  late FPopoverController _selectDisplayModeController;
  Map<ChaoXingCourse, List<ChaoXingExam>> _allExams = {};
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
    Map<ChaoXingCourse, List<ChaoXingExam>> result = {};

    // 获取课程列表
    final coursesResult = await GlobalService.chaoXingService?.getCourseList();
    final courses = coursesResult?.status == Status.ok
        ? coursesResult!.value as List<ChaoXingCourse>
        : [];

    for (final course in courses) {
      // 获取每个课程的考试
      final examsResult = await GlobalService.chaoXingService?.getExams(course);

      if (examsResult?.status == Status.ok) {
        List<ChaoXingExam> exams = (examsResult!.value as List<dynamic>).cast();
        if (exams.isNotEmpty) {
          result[course] = exams;
        }
      }
    }

    _refresh(() => _allExams = result);
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
        title: '学习通考试',
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
              '正在加载学习通考试...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_allExams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.clipboardCheck,
              size: 60,
              color: Colors.purple.withValues(alpha: 0.6),
            ),
            SizedBox(height: 16),
            Text(
              '这里没有考试~',
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
                '暂无考试信息，请检查是否已添加课程或稍后刷新',
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
      tabs: _allExams.keys.map((course) {
        return FTabEntry(
          label: Text(course.courseName),
          content: Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                ChaoXingCourseInfoCard(
                  course: course,
                  totalCount: _allExams[course]!.length,
                  type: '考试',
                ),
                _buildCourseExamsList(_allExams[course]!),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseExamsList(List<ChaoXingExam> exams) {
    // 按状态分组（三种状态分别显示）
    final pendingExams = exams.where((e) => e.status.contains('待做')).toList();
    final expiredExams = exams.where((e) => e.status.contains('已过期')).toList();
    final completedExams = exams
        .where((e) => !e.status.contains('待做') && !e.status.contains('已过期'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pendingExams.isNotEmpty) ...[
          _buildExamGroupHeader(
              '待考试', FontAwesomeIcons.clipboard, Colors.purple.shade700),
          ...pendingExams
              .map((exam) => _buildExamCard(exam, status: 'pending')),
          SizedBox(height: 16),
        ],
        if (expiredExams.isNotEmpty) ...[
          _buildExamGroupHeader(
              '已过期', FontAwesomeIcons.clockRotateLeft, Colors.orange.shade700),
          ...expiredExams
              .map((exam) => _buildExamCard(exam, status: 'expired')),
          SizedBox(height: 16),
        ],
        if (completedExams.isNotEmpty) ...[
          _buildExamGroupHeader(
              '已完成', FontAwesomeIcons.check, Colors.green.shade700),
          ...completedExams
              .map((exam) => _buildExamCard(exam, status: 'completed')),
        ],
      ],
    );
  }

  Widget _buildExamGroupHeader(String title, IconData icon, Color color) {
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

  Widget _buildExamCard(ChaoXingExam exam, {required String status}) {
    final Color statusColor;
    final IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.purple.shade700;
        statusIcon = FontAwesomeIcons.file;
        break;
      case 'expired':
        statusColor = Colors.orange.shade700;
        statusIcon = FontAwesomeIcons.fileCircleXmark;
        break;
      case 'completed':
      default:
        statusColor = Colors.green.shade700;
        statusIcon = FontAwesomeIcons.fileCircleCheck;
        break;
    }

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
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exam.title.trim(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _buildStatusBadge(exam.status, status),
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

  Widget _buildStatusBadge(String status, String examStatus) {
    final Color color;

    switch (examStatus) {
      case 'pending':
        color = Colors.purple.shade700;
        break;
      case 'expired':
        color = Colors.orange.shade700;
        break;
      case 'completed':
      default:
        color = Colors.green.shade700;
        break;
    }

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
