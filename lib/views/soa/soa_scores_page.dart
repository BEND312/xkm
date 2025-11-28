import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/circular_progress.dart';
import 'package:swustmeow/components/divider_with_text.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/entity/soa/score/course_score.dart';
import 'package:swustmeow/entity/soa/score/points_data.dart';
import 'package:swustmeow/entity/soa/score/score_type.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/math.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/utils/text.dart';
import 'package:swustmeow/utils/widget.dart';

import '../../components/utils/base_header.dart';
import '../../components/utils/base_page.dart';
import '../../data/m_theme.dart';
import '../../services/boxes/soa_box.dart';
import '../../utils/courses.dart';

class SOAScoresPage extends StatefulWidget {
  const SOAScoresPage({super.key});

  @override
  State<StatefulWidget> createState() => _SOAScoresPageState();
}

class _SOAScoresPageState extends State<SOAScoresPage>
    with SingleTickerProviderStateMixin {
  Map<ScoreType, List<CourseScore>> _scores = {};
  PointsData? _pointsData;
  bool _isLoading = true;
  bool _isRefreshing = false;
  static const _maxPoints = 5.0;
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _loadCache();
    await _loadScores();
    await _loadPoints();
    _refresh(() {
      _isLoading = false;
    });
  }

  Map<ScoreType, List<CourseScore>> _parseScores(List<CourseScore> scores) {
    Map<ScoreType, List<CourseScore>> result = {};
    for (final score in scores) {
      if (result.containsKey(score.scoreType)) {
        result[score.scoreType]!.add(score);
      } else {
        result[score.scoreType] = [score];
      }
    }
    return result;
  }

  void _loadCache() {
    List<CourseScore>? cachedScores =
        (SOABox.get('courseScores') as List<dynamic>?)?.cast() ?? [].cast();
    PointsData? cachedPointsData = SOABox.get('pointsData') as PointsData?;
    _refresh(() {
      _scores = _parseScores(cachedScores);
      _pointsData = cachedPointsData;
      if (cachedPointsData != null) {
        _isLoading = false;
      }
    });
  }

  Future<void> _loadScores() async {
    final service = GlobalService.soaService;
    if (service == null) return;

    final result = await service.getScores();
    if (result.status != Status.ok) return;

    _refresh(() {
      _scores = _parseScores((result.value as List<dynamic>).cast());
    });
  }

  Future<void> _loadPoints() async {
    final service = GlobalService.soaService;
    if (service == null) return;

    final result = await service.getPointsData();
    if (result.status != Status.ok) return;

    _refresh(() {
      _pointsData = result.value as PointsData;
    });
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
        title: '考试成绩',
        suffixIcons: [
          RefreshIcon(
            isRefreshing: _isRefreshing,
            onRefresh: () async {
              if (_isLoading || _isRefreshing) return;

              _refresh(() {
                _isRefreshing = true;
                _refreshAnimationController.repeat();
              });
              await _loadScores();
              await _loadPoints();
              _refresh(() {
                _isRefreshing = false;
                _refreshAnimationController.stop();
                _refreshAnimationController.reset();
              });
            },
          )
        ],
      ),
      content: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: joinGap(
                  gap: 8,
                  axis: Axis.vertical,
                  widgets: [
                    CircularProgressIndicator(
                      color: MTheme.primary2,
                    ),
                    Text('请耐心等待...'),
                    Text(
                      '课程较多时，加载需要较长时间',
                      style: TextStyle(fontSize: 14),
                    )
                  ],
                ),
              ),
            )
          : FTabs(
              initialIndex: _scores.isEmpty ? 0 : 1,
              tabs: [
                FTabEntry(
                  label: AutoSizeText(
                    '学分绩点',
                    maxLines: 1,
                    minFontSize: 8,
                  ),
                  content: _buildCreditsPage(),
                ),
                ..._scores.keys.map(
                  (key) {
                    final list = _scores[key]!;
                    final name = ScoreTypeData.of(key).name;
                    return FTabEntry(
                      label: AutoSizeText(
                        name,
                        maxLines: 1,
                        minFontSize: 8,
                      ),
                      content: Expanded(child: _buildContent(list)),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildCreditsPage() {
    final d = _pointsData;
    final w = MediaQuery.of(context).size.width;

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
      children: [
        // 学分信息卡片
        _buildCreditsCard(
          title: '学分统计',
          icon: FontAwesomeIcons.graduationCap,
          color: Colors.blueAccent,
          children: [
            _buildInfoBadge(
              FontAwesomeIcons.trophy,
              '总学分: ${d?.totalCredits?.toString() ?? '???'} 分',
              Colors.red,
            ),
            _buildInfoBadge(
              FontAwesomeIcons.book,
              '必修课学分: ${d?.requiredCoursesCredits?.toString() ?? '???'} 分',
              Colors.cyan.shade700,
            ),
          ],
        ),

        SizedBox(height: 16),

        // 绩点信息卡片
        _buildCreditsCard(
          title: '绩点统计',
          icon: FontAwesomeIcons.chartSimple,
          color: Colors.greenAccent.shade700,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: joinGap(
                gap: 8,
                axis: Axis.horizontal,
                widgets: [
                  _buildCircularProgress(
                    title: d?.averagePoints?.toString() ?? '???',
                    titleSize: 20,
                    subtitle: '平均绩点',
                    subtitleSize: 11,
                    maxValue: _maxPoints,
                    value: d?.averagePoints ?? 0,
                    size: (w - 80) / 3,
                    color: Colors.orange,
                  ),
                  _buildCircularProgress(
                    title: d?.requiredCoursesPoints?.toString() ?? '???',
                    titleSize: 20,
                    subtitle: '必修课绩点',
                    subtitleSize: 11,
                    maxValue: _maxPoints,
                    value: d?.requiredCoursesPoints ?? 0,
                    size: (w - 80) / 3,
                    color: Colors.teal,
                  ),
                  if (d?.degreeCoursesPoints != null)
                    _buildCircularProgress(
                      title:
                          d?.degreeCoursesPoints?.toString().padRight(5, '0') ??
                              '???',
                      titleSize: 20,
                      subtitle: '学位课绩点',
                      subtitleSize: 11,
                      maxValue: _maxPoints,
                      value: d?.degreeCoursesPoints ?? 0,
                      size: (w - 80) / 3,
                      color: Colors.purple,
                    ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCreditsCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(
                      icon,
                      color: color,
                      size: 14,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // 徽章行
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: children,
              ),
            ],
          ),
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

  Widget _buildCircularProgress({
    required String title,
    required double titleSize,
    required String subtitle,
    required double subtitleSize,
    required double maxValue,
    required double value,
    required double size,
    required Color color,
  }) {
    return CircularProgress(
      maxValue: maxValue,
      value: value,
      size: size,
      color: color,
      strokeWidth: 6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleSize,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: subtitleSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<CourseScore> scores) {
    if (scores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.fileCircleXmark,
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
                '当前学期暂无课程成绩数据，请稍后再查看或点击右上角刷新按钮重试',
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
                _refresh(() {
                  _isRefreshing = true;
                  _refreshAnimationController.repeat();
                });
                await _loadScores();
                await _loadPoints();
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

    Map<String, List<CourseScore>> map = {};

    for (final score in scores) {
      final term = score.term;
      if (map.containsKey(term)) {
        map[term]!.add(score);
      } else {
        map[term] = [score];
      }
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0),
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemCount: map.length,
      itemBuilder: (context, i) {
        final term = map.keys.toList()[i];
        final scores = map[term]!;

        return Column(
          children: joinGap(
            gap: 8,
            axis: Axis.vertical,
            widgets: [
              DividerWithText(
                crossAxisAlignment: CrossAxisAlignment.start,
                child: Text(
                  term,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...scores.map((score) => _buildCard(score))
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(CourseScore score) {
    // 计算绩点并根据分数确定颜色
    final scoreColor = getCourseScoreColor(score.formalScore);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
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
                color: scoreColor,
              ),

              // 课程信息区
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 课程名称和类型
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (score.courseType != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: MTheme.primary1.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                score.courseType!,
                                style: TextStyle(
                                  color: MTheme.primary1,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              score.courseName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // 课程相关信息
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoBadge(
                            FontAwesomeIcons.idCard,
                            '课程号: ${score.courseId}',
                            Colors.blue,
                          ),
                          _buildInfoBadge(
                            FontAwesomeIcons.medal,
                            '学分: ${score.credit}',
                            Colors.green,
                          ),
                          if (score.points != null)
                            _buildInfoBadge(
                              FontAwesomeIcons.chartLine,
                              '绩点: ${score.points}',
                              Colors.purple,
                            ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // 成绩展示区
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                                  color: scoreColor,
                                ),
                              ),
                            ],
                          ),
                          if (!score.resitScore.isContentEmpty)
                            Text(
                              '补考: ${double.tryParse(score.resitScore)?.intOrDouble?.splice('分') ?? score.resitScore}',
                              style: TextStyle(
                                color: getCourseScoreColor(score.resitScore),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )
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
}
