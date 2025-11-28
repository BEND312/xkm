import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/entity/soa/course/course_entry.dart';
import 'package:swustmeow/services/boxes/course_box.dart';
import 'package:swustmeow/services/value_service.dart';
import 'package:swustmeow/utils/widget.dart';
import 'package:swustmeow/views/course_table/custom_course/custom_course_edit_page.dart';

import '../../../data/m_theme.dart';
import '../../../services/global_service.dart';

class CourseTableCustomCoursesPage extends StatefulWidget {
  const CourseTableCustomCoursesPage({super.key});

  @override
  State<CourseTableCustomCoursesPage> createState() =>
      _CourseTableCustomCoursesPageState();
}

class _CourseTableCustomCoursesPageState
    extends State<CourseTableCustomCoursesPage> {
  Map<String, List<dynamic>> _customCourses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Map<String, dynamic> customCourses =
        (CourseBox.get('customCourses') as Map<dynamic, dynamic>? ?? {}).cast();
    _refresh(() {
      _customCourses = customCourses.cast();
      _isLoading = false;
    });
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  void _showAddEditCourseDialog([CourseEntry? course]) async {
    final result = await Navigator.push<CourseEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomCourseEditPage(course: course),
      ),
    );

    if (result != null) {
      final containerId = result.containerId!;
      if (!_customCourses.containsKey(containerId)) {
        _customCourses[containerId] = [];
      }

      if (course != null) {
        final index = _customCourses[containerId]!.indexOf(course);
        _customCourses[containerId]![index] = result;
      } else {
        _customCourses[containerId]!.add(result);
      }
      await CourseBox.put('customCourses', _customCourses);
      ValueService.customCourses = _customCourses;
      GlobalService.refreshHomeCourseWidgets();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: _buildHeader(),
      content: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: MTheme.primary2,
              ),
            )
          : _customCourses.isEmpty
              ? _buildEmptyState()
              : _buildCoursesList(),
    );
  }

  Widget _buildHeader() {
    return BaseHeader(
      title: Text(
        '自定义课程',
        style: TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      suffixIcons: [
        IconButton(
          icon: FaIcon(
            FontAwesomeIcons.plus,
            color: MTheme.backgroundText,
            size: 20,
          ),
          onPressed: () => _showAddEditCourseDialog(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FontAwesomeIcons.calendar,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16),
          Text(
            '暂无自定义课程\n点击右上角添加',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    final containers = ValueService.coursesContainers;
    final coursesByTerm = <String, List<CourseEntry>>{};

    _customCourses.forEach((_, courses) {
      for (var course in courses) {
        try {
          final container =
              containers.singleWhere((c) => c.id == course.containerId);
          final termDisplay = container.parseDisplayString();
          coursesByTerm.putIfAbsent(termDisplay, () => []).add(course);
        } catch (e) {
          coursesByTerm.putIfAbsent('未分类', () => []).add(course);
        }
      }
    });

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: coursesByTerm.length,
      itemBuilder: (context, index) {
        final term = coursesByTerm.keys.elementAt(index);
        final courses = coursesByTerm[term]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                term,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ...courses.map((course) => _buildCourseCard(course)),
            SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildCourseCard(CourseEntry course) {
    final color = course.getColor();

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
                color: color,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: color.withValues(alpha: 0.05),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCourseHeader(course),
                    SizedBox(height: 6),
                    _buildCourseInfo(course),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader(CourseEntry course) {
    return Row(
      children: [
        Expanded(
          child: Text(
            course.courseName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildActionButtons(course),
      ],
    );
  }

  Widget _buildActionButtons(CourseEntry course) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: joinGap(
        gap: 8,
        axis: Axis.horizontal,
        widgets: [
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              icon: FaIcon(
                FontAwesomeIcons.penToSquare,
                size: 16,
                color: MTheme.primary2,
              ),
              onPressed: () => _showAddEditCourseDialog(course),
            ),
          ),
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              icon: FaIcon(
                FontAwesomeIcons.trashCan,
                size: 16,
                color: Colors.red,
              ),
              onPressed: () async {
                final containerId = course.containerId!;
                _customCourses[containerId]!.remove(course);
                if (_customCourses[containerId]!.isEmpty) {
                  _customCourses.remove(containerId);
                }
                await CourseBox.put('customCourses', _customCourses);
                ValueService.customCourses = _customCourses;
                GlobalService.refreshHomeCourseWidgets();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfo(CourseEntry course) {
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInfoBadge(
          FontAwesomeIcons.locationDot,
          course.place,
          Colors.blue,
        ),
        _buildInfoBadge(
          FontAwesomeIcons.calendar,
          '星期${days[course.weekday - 1]}',
          Colors.green,
        ),
        _buildInfoBadge(
          FontAwesomeIcons.clock,
          '第${course.startSection}-${course.endSection}节',
          Colors.orange,
        ),
        _buildInfoBadge(
          FontAwesomeIcons.calendar,
          course.startWeek != course.endWeek
              ? '第${course.startWeek}-${course.endWeek}周'
              : '第${course.startWeek}周',
          Colors.purple,
        ),
        if (course.teacherName.isNotEmpty)
          _buildInfoBadge(
            FontAwesomeIcons.user,
            course.teacherName.first,
            Colors.teal,
          ),
      ],
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 11,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
