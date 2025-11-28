import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/data/values.dart';
import 'package:swustmeow/entity/soa/exam/exam_schedule.dart';
import 'package:swustmeow/entity/soa/exam/exam_type.dart';
import 'package:swustmeow/entity/soa/score/course_score.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/math.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/utils/text.dart';
import 'package:swustmeow/utils/time.dart';

import '../../components/utils/base_page.dart';
import '../../data/m_theme.dart';
import '../../services/boxes/soa_box.dart';
import '../../utils/courses.dart';

class SOAExamsPage extends StatefulWidget {
  const SOAExamsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SOAExamsPageState();
}

class _SOAExamsPageState extends State<SOAExamsPage>
    with SingleTickerProviderStateMixin {
  Map<ExamType, List<ExamSchedule>> _exams = {};
  List<CourseScore> _scores = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _loadCache();
    _loadData();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _loadCache() {
    List<ExamSchedule>? exams =
        (SOABox.get('examSchedules') as List<dynamic>?)?.cast();
    List<CourseScore>? scores =
        (SOABox.get('courseScores') as List<dynamic>?)?.cast();
    if (exams?.isNotEmpty == true) {
      _refresh(() {
        _exams = _parseMap(exams!);
        _isLoading = false;
      });
    }
    if (scores?.isNotEmpty == true) {
      _refresh(() => _scores = scores!);
    }
  }

  Future<void> _loadData() async {
    await _loadExams();
    await _loadScores();
    _refresh(() => _isLoading = false);
  }

  Map<ExamType, List<ExamSchedule>> _parseMap(List<ExamSchedule> exams) {
    Map<ExamType, List<ExamSchedule>> result = {};
    for (final exam in exams) {
      final list = result[exam.type];
      if (list == null) result[exam.type] = [];
      result[exam.type]!.add(exam);
    }
    return result;
  }

  Future<void> _loadExams() async {
    final service = GlobalService.soaService;
    if (service == null) return;

    final result = await service.getExams();
    if (result.status != Status.ok) return;

    _refresh(() {
      _exams = _parseMap((result.value as List<dynamic>).cast());
    });
  }

  Future<void> _loadScores() async {
    final service = GlobalService.soaService;
    if (service == null) return;

    final result = await service.getScores();
    if (result.status != Status.ok) return;

    _refresh(() {
      _scores = (result.value as List<dynamic>).cast();
    });
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(
        title: '考试',
        suffixIcons: [
          RefreshIcon(
            isRefreshing: _isRefreshing,
            onRefresh: () async {
              if (_isRefreshing || _isLoading) return;
              _refresh(() => _isRefreshing = true);
              _refreshAnimationController.repeat();
              await _loadData();
              _refresh(() {
                _isRefreshing = false;
                _refreshAnimationController.stop();
                _refreshAnimationController.reset();
              });
            },
          )
        ],
      ),
      content: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: MTheme.primary2,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              '加载考试数据中...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.calendarXmark,
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
                '当前无考试安排数据，请稍后再查看或点击右上角刷新按钮',
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
                if (_isRefreshing || _isLoading) return;
                _refresh(() => _isRefreshing = true);
                _refreshAnimationController.repeat();
                await _loadData();
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
      tabs: _exams.entries.map(
        (entry) {
          final name = switch (entry.key) {
            ExamType.finalExam => '期末考试',
            ExamType.midExam => '期中考试',
            ExamType.resitExam => '补考',
          };
          final exams = entry.value;
          final now = DateTime.now();
          final unfinished = exams.where((e) => e.isActive).toList()
            ..sort((a, b) {
              final aDiff = a.date - now;
              final bDiff = b.date - now;
              return aDiff > bDiff
                  ? 1
                  : aDiff == bDiff
                      ? 0
                      : -1;
            });
          final finished = exams.where((e) => !e.isActive).toList()
            ..sort((a, b) {
              final aDiff = now - a.date;
              final bDiff = now - b.date;
              return aDiff > bDiff
                  ? 1
                  : aDiff == bDiff
                      ? 0
                      : -1;
            });
          final result = [...unfinished, ...finished];

          return FTabEntry(
            label: Text(name),
            content: Expanded(child: _buildList(result)),
          );
        },
      ).toList(),
    );
  }

  Widget _buildList(List<ExamSchedule> exams) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0),
      separatorBuilder: (context, index) => SizedBox(height: 12.0),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final score = _scores
            .where((s) => s.courseName.trim() == exam.courseName.trim())
            .firstOrNull;
        final time = Values.courseTableTimes[exam.numberOfDay - 1];
        final numbers = ['一', '二', '三', '四', '五', '六', '日'];

        return _buildExamCard(exam, score, time, numbers);
      },
    );
  }

  Widget _buildExamCard(ExamSchedule exam, CourseScore? score, String time,
      List<String> numbers) {
    final isActive = exam.isActive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧状态条
              Container(
                width: 4,
                color: isActive ? MTheme.primary2 : Colors.grey.shade400,
              ),
              // 考试信息
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 课程名称和状态徽章
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              exam.courseName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          _buildStatusBadge(isActive),
                        ],
                      ),
                      SizedBox(height: 12),

                      // 考试信息
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoBadge(
                            FontAwesomeIcons.calendar,
                            '${exam.date.year}-${exam.date.month.padL2}-${exam.date.day.padL2}',
                            Colors.blue,
                          ),
                          _buildInfoBadge(
                            FontAwesomeIcons.clock,
                            '周${numbers[exam.weekday - 1]}第${numbers[exam.numberOfDay - 1]}场 ${time.split('\n').join('-')}',
                            Colors.orange,
                          ),
                          _buildInfoBadge(
                            FontAwesomeIcons.locationDot,
                            '${exam.place}-${exam.classroom}',
                            Colors.green,
                          ),
                          _buildInfoBadge(
                            FontAwesomeIcons.chair,
                            '座次${exam.seatNo}',
                            Colors.teal,
                          ),
                        ],
                      ),

                      // 成绩信息 (如果有)
                      if (score != null && !isActive) ...[
                        SizedBox(height: 12),
                        Divider(
                            height: 1,
                            color: Colors.grey.withValues(alpha: 0.2)),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '成绩：',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              double.tryParse(score.formalScore)
                                      ?.intOrDouble
                                      ?.splice('分') ??
                                  score.formalScore,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: getCourseScoreColor(score.formalScore),
                              ),
                            ),
                            if (!score.resitScore.isContentEmpty) ...[
                              SizedBox(width: 8),
                              _buildScoreBadge(
                                '补考: ${double.tryParse(score.resitScore)?.intOrDouble?.splice('分') ?? score.resitScore}',
                                getCourseScoreColor(score.resitScore),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  Widget _buildStatusBadge(bool isActive) {
    final text = isActive ? '待考' : '已结束';
    final color = isActive ? MTheme.primary2 : Colors.grey.shade500;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 12,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
}
