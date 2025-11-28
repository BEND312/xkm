import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/entity/soa/course/course_entry.dart';
import 'package:swustmeow/services/value_service.dart';
import 'package:swustmeow/utils/common.dart';

import '../../../data/m_theme.dart';
import '../../../entity/soa/course/courses_container.dart';

class CustomCourseEditPage extends StatefulWidget {
  const CustomCourseEditPage({super.key, this.course});

  final CourseEntry? course;

  @override
  State<StatefulWidget> createState() => _CustomCourseEditPageState();
}

class _CustomCourseEditPageState extends State<CustomCourseEditPage> {
  late bool isEditing;
  late List<CoursesContainer> containers;
  late CoursesContainer? container;
  late TextEditingController nameController;
  late TextEditingController teacherController;
  late TextEditingController placeController;
  late int selectedWeekday;
  late int startWeek;
  late int endWeek;
  late int startSection;
  late int endSection;
  final _containerController = FRadioSelectGroupController<String>();
  final _weekdayController = FRadioSelectGroupController<int>();
  final _startWeekController = FRadioSelectGroupController<int>();
  final _endWeekController = FRadioSelectGroupController<int>();
  final _startSectionController = FRadioSelectGroupController<int>();
  final _endSectionController = FRadioSelectGroupController<int>();

  @override
  void initState() {
    super.initState();
    isEditing = widget.course != null;
    containers = ValueService.coursesContainers;
    container = containers
            .where((c) => c.id == widget.course?.containerId)
            .firstOrNull ??
        ValueService.currentCoursesContainer.value;

    if (container == null) {
      showErrorToast('未能获取到课表信息，请重试');
      return;
    }

    nameController = TextEditingController(text: widget.course?.courseName);
    teacherController = TextEditingController(
        text: widget.course?.teacherName.isNotEmpty == true
            ? widget.course!.teacherName.first
            : '');
    placeController = TextEditingController(text: widget.course?.place);
    selectedWeekday = (widget.course?.weekday ?? 1) - 1;
    startWeek = (widget.course?.startWeek ?? 1) - 1;
    endWeek = (widget.course?.endWeek ?? 1) - 1;
    startSection = (widget.course?.startSection ?? 1) - 1;
    endSection = (widget.course?.endSection ?? 2) - 1;
  }

  @override
  void dispose() {
    nameController.dispose();
    teacherController.dispose();
    placeController.dispose();
    _containerController.dispose();
    _weekdayController.dispose();
    _startWeekController.dispose();
    _endWeekController.dispose();
    _startSectionController.dispose();
    _endSectionController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    // 检查课程名称
    if (nameController.text.trim().isEmpty) {
      showErrorToast('请输入课程名称');
      return;
    }

    // 检查教师姓名
    if (teacherController.text.trim().isEmpty) {
      showErrorToast('请输入教师姓名');
      return;
    }

    // 检查上课地点
    if (placeController.text.trim().isEmpty) {
      showErrorToast('请输入上课地点');
      return;
    }

    // 检查周数
    if (startWeek > endWeek) {
      showErrorToast('开始周数不能大于结束周数');
      return;
    }

    // 检查节数
    if (startSection > endSection) {
      showErrorToast('开始节数不能大于结束节数');
      return;
    }

    // 检查节数范围
    if (startSection < 0 ||
        startSection > 11 ||
        endSection < 0 ||
        endSection > 11) {
      showErrorToast('节数必须在1-12之间');
      return;
    }

    // 检查周数范围
    final weeks = container!.getWeeksNum();
    if (startWeek < 0 || startWeek > weeks || endWeek < 0 || endWeek > weeks) {
      showErrorToast('周数必须在1-$weeks之间');
      return;
    }

    // 所有验证通过，创建新课程
    final newCourse = CourseEntry(
      courseName: nameController.text.trim(),
      teacherName: [teacherController.text.trim()],
      startWeek: startWeek + 1,
      endWeek: endWeek + 1,
      place: placeController.text.trim(),
      weekday: selectedWeekday + 1,
      numberOfDay: (startSection + 1) % 2 == 0
          ? ((startSection + 1) / 2).toInt()
          : (((startSection + 1) + 1) / 2).toInt(),
      displayName: nameController.text.trim(),
      startSection: startSection + 1,
      endSection: endSection + 1,
      isCustom: true,
      containerId: container?.id,
    );

    Navigator.pop(context, newCourse);
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 14, color: Colors.black);
    final detailStyle = TextStyle(
      fontSize: 14,
      color: Colors.black.withValues(alpha: 0.6),
    );
    final days = ['一', '二', '三', '四', '五', '六', '日'];

    return BasePage(
      headerPad: false,
      header: BaseHeader(
        title: isEditing ? '编辑课程' : '添加课程',
        suffixIcons: [
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.check,
              color: MTheme.backgroundText,
              size: 20,
            ),
            onPressed: _validateAndSave,
          ),
        ],
      ),
      content: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionTitle('基本信息'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                FSelectMenuTile<String>.builder(
                  title: Text('课表', style: style),
                  groupController: _containerController
                    ..update(container!.id!, selected: true)
                    ..addValueListener((values) {
                      final value = values.first;
                      setState(() => container =
                          containers.singleWhere((c) => c.id == value));
                    }),
                  autoHide: true,
                  count: containers.length,
                  maxHeight: 140,
                  menuTileBuilder: (context, index) {
                    final c = containers[index];
                    return FSelectTile(
                      title: Text(c.parseDisplayString()),
                      value: c.id!,
                    );
                  },
                  details: ValueListenableBuilder(
                    valueListenable: _containerController,
                    builder: (context, values, child) {
                      final value = values.first;
                      return Text(
                          containers
                              .singleWhere((c) => c.id == value)
                              .parseDisplayString(),
                          style: detailStyle);
                    },
                  ),
                ),
                SizedBox(height: 8),
                _buildTextField(
                  '课程名称',
                  nameController,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        '教师姓名',
                        teacherController,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        '上课地点',
                        placeController,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildSectionTitle('时间安排'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                FSelectMenuTile<int>.builder(
                  title: Text('星期数', style: style),
                  groupController: _weekdayController
                    ..update(selectedWeekday, selected: true)
                    ..addValueListener((values) {
                      final value = values.first;
                      setState(() => selectedWeekday = value);
                    }),
                  autoHide: true,
                  count: days.length,
                  maxHeight: 140,
                  menuTileBuilder: (context, index) {
                    return FSelectTile(
                      title: Text('星期${days[index]}'),
                      value: index,
                    );
                  },
                  details: ValueListenableBuilder(
                    valueListenable: _weekdayController,
                    builder: (context, values, child) {
                      final value = values.first;
                      return Text('星期${days[value]}', style: detailStyle);
                    },
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FSelectMenuTile<int>.builder(
                        title:
                        AutoSizeText('开始周数', maxLines: 1, style: style),
                        groupController: _startWeekController
                          ..update(startWeek, selected: true)
                          ..addValueListener((values) {
                            final value = values.first;
                            setState(() => startWeek = value);
                          }),
                        autoHide: true,
                        count: 20,
                        maxHeight: 140,
                        menuTileBuilder: (context, index) {
                          return FSelectTile(
                            title: Text('第${index + 1}周'),
                            value: index,
                          );
                        },
                        details: ValueListenableBuilder(
                          valueListenable: _startWeekController,
                          builder: (context, values, child) {
                            final value = values.first;
                            return Text('第${value + 1}周', style: detailStyle);
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: FSelectMenuTile<int>.builder(
                        title:
                        AutoSizeText('结束周数', maxLines: 1, style: style),
                        groupController: _endWeekController
                          ..update(endWeek, selected: true)
                          ..addValueListener((values) {
                            final value = values.first;
                            setState(() => endWeek = value);
                          }),
                        autoHide: true,
                        count: 20,
                        maxHeight: 140,
                        menuTileBuilder: (context, index) {
                          return FSelectTile(
                            title: Text('第${index + 1}周'),
                            value: index,
                          );
                        },
                        details: ValueListenableBuilder(
                          valueListenable: _endWeekController,
                          builder: (context, values, child) {
                            final value = values.first;
                            return Text('第${value + 1}周', style: detailStyle);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FSelectMenuTile<int>.builder(
                        title:
                        AutoSizeText('开始节数', maxLines: 1, style: style),
                        groupController: _startSectionController
                          ..update(startSection, selected: true)
                          ..addValueListener((values) {
                            final value = values.first;
                            setState(() => startSection = value);
                          }),
                        autoHide: true,
                        count: 12,
                        maxHeight: 140,
                        menuTileBuilder: (context, index) {
                          return FSelectTile(
                            title: Text('第${index + 1}节'),
                            value: index,
                          );
                        },
                        details: ValueListenableBuilder(
                          valueListenable: _startSectionController,
                          builder: (context, values, child) {
                            final value = values.first;
                            return Text('第${value + 1}节', style: detailStyle);
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: FSelectMenuTile<int>.builder(
                        title:
                        AutoSizeText('结束节数', maxLines: 1, style: style),
                        groupController: _endSectionController
                          ..update(endSection, selected: true)
                          ..addValueListener((values) {
                            final value = values.first;
                            setState(() => endSection = value);
                          }),
                        autoHide: true,
                        count: 12,
                        maxHeight: 140,
                        menuTileBuilder: (context, index) {
                          return FSelectTile(
                            title: Text('第${index + 1}节'),
                            value: index,
                          );
                        },
                        details: ValueListenableBuilder(
                          valueListenable: _endSectionController,
                          builder: (context, values, child) {
                            final value = values.first;
                            return Text('第${value + 1}节', style: detailStyle);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: MTheme.primary2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
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
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    required TextInputAction textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.black87)),
        SizedBox(height: 4),
        FTextField(
          controller: controller,
          textInputAction: textInputAction,
        ),
      ],
    );
  }
}
