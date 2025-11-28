import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/components/simple_setting_item.dart';
import 'package:swustmeow/components/simple_settings_group.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/utils/widget.dart';
import 'package:swustmeow/views/course_table/custom_course/course_table_custom_courses_page.dart';
import 'package:swustmeow/views/course_table/course_table_display_settings_page.dart';
import 'package:swustmeow/views/course_table/course_table_theme_settings_page.dart';

import '../../data/m_theme.dart';

class CourseTableSettingsPage extends StatelessWidget {
  final Function() onRefresh;

  const CourseTableSettingsPage({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '课程表设置'),
      content: Padding(
        padding: EdgeInsets.all(MTheme.radius),
        child: _buildSettings(context),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.none,
      children: joinGap(
        gap: 8,
        axis: Axis.vertical,
        widgets: [
          _buildCourseTableSetting(context),
          _buildCustomCoursesSetting(context),
        ],
      ),
    );
  }

  Widget _buildCourseTableSetting(BuildContext context) {
    return SimpleSettingsGroup(
      children: [
        SimpleSettingItem(
          title: '课程表显示设置',
          subtitle: '自定义课程表显示方式',
          icon: FontAwesomeIcons.eye,
          onPress: () {
            pushTo(context, '/course_table/settings/display',
                const CourseTableDisplaySettingsPage());
          },
        ),
        SimpleSettingItem(
          title: '课程表样式设置',
          subtitle: '自定义背景、配色与样式',
          icon: FontAwesomeIcons.palette,
          onPress: () {
            pushTo(
              context,
              '/course_table/settings/theme',
              CourseTableThemeSettingsPage(
                onRefresh: onRefresh,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomCoursesSetting(BuildContext context) {
    return SimpleSettingsGroup(
      children: [
        SimpleSettingItem(
          title: '自定义课程',
          subtitle: '添加、编辑、删除自定义课程',
          icon: FontAwesomeIcons.pencil,
          onPress: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CourseTableCustomCoursesPage(),
              ),
            );
            onRefresh();
          },
        ),
      ],
    );
  }
}
