import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/components/header_selector.dart';
import 'package:swustmeow/components/utils/empty.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/activity.dart';
import 'package:swustmeow/services/boxes/course_box.dart';
import 'package:swustmeow/utils/courses.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/utils/status.dart';

import '../../components/course_table/course_table.dart';
import '../../components/utils/base_header.dart';
import '../../components/utils/base_page.dart';
import '../../entity/soa/course/courses_container.dart';
import '../../entity/soa/exam/exam_schedule.dart';
import '../../services/boxes/soa_box.dart';
import '../../services/global_service.dart';
import '../../services/value_service.dart';
import '../../utils/exam_converter.dart';
import 'course_table_settings_page.dart';

class CourseTablePage extends StatefulWidget {
  final List<CoursesContainer> containers;
  final CoursesContainer currentContainer;
  final List<Activity> activities;
  final bool showBackButton;

  const CourseTablePage({
    super.key,
    required this.containers,
    required this.currentContainer,
    required this.activities,
    required this.showBackButton,
  });

  @override
  State<StatefulWidget> createState() => _CourseTablePageState();
}

class _CourseTablePageState extends State<CourseTablePage>
    with SingleTickerProviderStateMixin {
  late List<CoursesContainer> _containers;
  late CoursesContainer _currentContainer;
  bool _isLoading = false;
  late AnimationController _refreshAnimationController;
  late String? userId;
  late List<CoursesContainer> containers;

  @override
  void initState() {
    super.initState();
    _containers = widget.containers;
    _currentContainer = widget.currentContainer;
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    userId = GlobalService.soaService?.currentAccount?.account;
    containers = _containers;
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  CoursesContainer _getContainerWithExams(CoursesContainer container) {
    final showExams = CourseBox.get('showExamsInCourseTable') as bool? ?? false;
    if (!showExams) return container;
    final exams = (SOABox.get('examSchedules') as List<dynamic>?)?.cast<ExamSchedule>() ?? [];
    if (exams.isEmpty) return container;
    return ExamConverter.mergeExamsToContainer(
      container: container,
      exams: exams,
      filterByTerm: true,
    );
  }

  void _reloadCustomCourses() {
    ValueService.customCourses =
        (CourseBox.get('customCourses') as Map<dynamic, dynamic>? ?? {}).cast();
    final containersWithCustomCourses =
        _containers.map((cc) => cc.withCustomCourses).toList();
    final current = containersWithCustomCourses.where((c) => c.id == _currentContainer.id);
    if (current.isNotEmpty) {
      _refresh(() {
        containers = containersWithCustomCourses;
        _currentContainer = current.first;
        ValueService.coursesContainers = containersWithCustomCourses;
        ValueService.currentCoursesContainer.value = _currentContainer;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = MTheme.courseTableImagePath;
    final enableBackgroundBlur =
        CourseBox.get('enableBackgroundBlur') as bool? ?? false;
    final backgroundBlurSigma =
        CourseBox.get('backgroundBlurSigma') as double? ?? 5.0;

    return BasePage(
      headerPad: false,
      extraHeight: MTheme.radius,
      backgroundImage: imagePath != null
          ? DecorationImage(
              image: FileImage(File(imagePath)),
              fit: BoxFit.cover,
            )
          : null,
      blurBackground: imagePath != null && enableBackgroundBlur,
      blurSigma: backgroundBlurSigma,
      header: _buildHeader(),
      content: Padding(
        padding: EdgeInsets.only(top: 4.0),
        child: CourseTable(
          container: _getContainerWithExams(_currentContainer),
          isLoading: _isLoading,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasBg = MTheme.courseTableImagePath != null;
    final color = hasBg
        ? MTheme.courseTableUseWhiteFont
            ? Colors.white
            : Colors.black
        : MTheme.backgroundText;
    final titleStyle = TextStyle(fontSize: 14, color: Colors.white);

    return BaseHeader(
      color: color,
      showBackButton: widget.showBackButton,
      title: HeaderSelector<String>(
        enabled: !_isLoading,
        initialValue: _currentContainer.id,
        color: color,
        onSelect: (value) {
          final container = containers.where((c) => c.id == value).firstOrNull;
          if (container != null) {
            _refresh(() => _currentContainer = container);
          }
        },
        count: containers.length,
        titleBuilder: (context, value) {
          return Align(
            alignment: Alignment.centerRight,
            child: Column(
              children: [
                Text(
                  '课程表',
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: color,
                  ),
                ),
                AutoSizeText(
                  containers
                          .where((c) => c.id == value)
                          .firstOrNull
                          ?.parseDisplayString() ??
                      '',
                  maxLines: 1,
                  maxFontSize: 12,
                  minFontSize: 8,
                  style: TextStyle(color: color),
                ),
              ],
            ),
          );
        },
        tileValueBuilder: (context, index) => containers[index].id!,
        tileTextBuilder: (context, index) {
          final container = containers[index];
          return Row(
            children: [
              SizedBox(width: 28),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      container.term,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '我的课表',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 30,
                child: const Empty(),
              ),
            ],
          );
        },
        fallbackTitle: Text('未知学期', style: titleStyle),
      ),
      suffixIcons: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PopScope(
                  canPop: true,
                  onPopInvokedWithResult: (didPop, _) {
                    if (didPop) {
                      _reloadCustomCourses();
                    }
                  },
                  child: CourseTableSettingsPage(
                    onRefresh: () {
                      _reloadCustomCourses();
                    },
                  ),
                ),
              ),
            );
          },
          icon: FaIcon(
            FontAwesomeIcons.gear,
            color: color,
            size: 20,
          ),
        ),
        RefreshIcon(
          color: color,
          isRefreshing: _isLoading,
          onRefresh: () async {
            if (_isLoading) return;
            await _refreshCourseTable();
          },
        ),
      ],
    );
  }

  Future<void> _refreshCourseTable() async {
    _refresh(() {
      _isLoading = true;
      _refreshAnimationController.repeat();
    });

    try {
      // 获取自己的课表
      final res = await GlobalService.soaService!.getCourseTables();
      if (res.status != Status.ok) return;

      List<CoursesContainer> containers = (res.value as List<dynamic>).cast();
      final current = containers.where((c) => c.id == _currentContainer.id);
      await CourseBox.put('courseTables', containers);

      _refresh(() {
        _containers = containers;
        _currentContainer = current.isNotEmpty
            ? current.first
            : getCurrentCoursesContainer(widget.activities, containers);
        ValueService.coursesContainers = _containers;
        ValueService.currentCoursesContainer.value = _currentContainer;
      });
    } finally {
      GlobalService.refreshHomeCourseWidgets();
      _refresh(() {
        _isLoading = false;
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
      });
    }
  }
}
