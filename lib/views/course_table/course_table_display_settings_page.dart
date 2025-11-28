import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/simple_setting_item.dart';
import 'package:swustmeow/components/simple_settings_group.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/services/boxes/course_box.dart';
import 'package:swustmeow/utils/widget.dart';

class CourseTableDisplaySettingsPage extends StatefulWidget {
  const CourseTableDisplaySettingsPage({super.key});

  @override
  State<CourseTableDisplaySettingsPage> createState() =>
      _CourseTableDisplaySettingsPageState();
}

class _CourseTableDisplaySettingsPageState
    extends State<CourseTableDisplaySettingsPage> {
  late bool _showSubCourseName;
  late bool _showRedBorderForConflict;
  late bool _showStarForMultiCandidates;
  late bool _showExamsInCourseTable;

  @override
  void initState() {
    super.initState();
    _showSubCourseName = CourseBox.get('showSubCourseName') as bool? ?? false;
    _showRedBorderForConflict =
        CourseBox.get('showRedBorderForConflict') as bool? ?? true;
    _showStarForMultiCandidates =
        CourseBox.get('showStarForMultiCandidates') as bool? ?? false;
    _showExamsInCourseTable =
        CourseBox.get('showExamsInCourseTable') as bool? ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '课程表显示设置'),
      content: _buildList(),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: joinGap(
        gap: 8,
        axis: Axis.vertical,
        widgets: [
          SimpleSettingsGroup(
            title: '显示样式',
            children: [
              SimpleSettingItem(
                title: '优先显示子课程名称',
                subtitle: '多用于实验课，优先使用子课程名称（项目名称）显示，而不是主要课程名称（课程的总名称）',
                icon: FontAwesomeIcons.textWidth,
                suffix: FSwitch(
                  value: _showSubCourseName,
                  onChange: (value) async {
                    await CourseBox.put('showSubCourseName', value);
                    setState(() => _showSubCourseName = value);
                  },
                ),
              ),
            ],
          ),
          SimpleSettingsGroup(
            title: '考试显示',
            children: [
              SimpleSettingItem(
                title: '在课表中显示考试',
                subtitle: '将考试安排显示在课程表中，方便查看考试时间和地点',
                icon: FontAwesomeIcons.clipboardCheck,
                suffix: FSwitch(
                  value: _showExamsInCourseTable,
                  onChange: (value) async {
                    await CourseBox.put('showExamsInCourseTable', value);
                    setState(() => _showExamsInCourseTable = value);
                  },
                ),
              ),
            ],
          ),
          SimpleSettingsGroup(
            title: '课表提示',
            children: [
              SimpleSettingItem(
                title: '重课提示',
                subtitle: '两个或多个课程冲突（不同课程在同一周、同一天、同一节）时显示红色边框提示',
                icon: FontAwesomeIcons.triangleExclamation,
                suffix: FSwitch(
                  value: _showRedBorderForConflict,
                  onChange: (value) async {
                    await CourseBox.put('showRedBorderForConflict', value);
                    setState(() => _showRedBorderForConflict = value);
                  },
                ),
              ),
              SimpleSettingItem(
                title: '多候选课程提示',
                subtitle: '在具有多个候选课程的课程名称前显示星号（*）标记，表示当前课程所在的位置存在多个课程',
                icon: FontAwesomeIcons.asterisk,
                suffix: FSwitch(
                  value: _showStarForMultiCandidates,
                  onChange: (value) async {
                    await CourseBox.put('showStarForMultiCandidates', value);
                    setState(() => _showStarForMultiCandidates = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
