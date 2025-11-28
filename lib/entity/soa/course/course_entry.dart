import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/color_mode.dart';
import 'package:swustmeow/services/boxes/common_box.dart';

import '../../../services/boxes/course_box.dart';
import '../../../utils/color.dart';

part 'course_entry.g.dart';

@JsonSerializable()
@HiveType(typeId: 1)
class CourseEntry {
  CourseEntry({
    required this.courseName,
    required this.teacherName,
    required this.startWeek,
    required this.endWeek,
    required this.place,
    required this.weekday,
    required this.numberOfDay,
    this.color = 0xFF000000,
    required this.displayName,
    this.startSection,
    this.endSection,
    this.isCustom,
    this.containerId,
    this.isExam,
  }) {
    if (color == 0xFF000000) {
      gen([int? salt]) {
        int color = generateColorFromString(
          courseName + (salt == null ? '' : '$salt'),
          minBrightness: 0.5,
          saturationFactor: 0.7,
        ).toInt();
        this.color = color;
      }

      int times = 0;
      gen();

      while (Color(color).computeLuminance() > 0.7) {
        gen(times);
        times++;
      }
    }
  }

  @JsonKey(name: 'course_name')
  @HiveField(0)
  final String courseName;

  @JsonKey(name: 'teacher_name')
  @HiveField(1)
  final List<String> teacherName;

  @JsonKey(name: 'start_week')
  @HiveField(2)
  final int startWeek;

  @JsonKey(name: 'end_week')
  @HiveField(3)
  final int endWeek;

  @JsonKey(name: 'place')
  @HiveField(4)
  final String place;

  @JsonKey(name: 'weekday')
  @HiveField(5)
  final int weekday;

  /// 已被弃用，结果是错误的
  @Deprecated('请使用 \'startSection\' 和 \'endSection\'')
  @JsonKey(name: 'number_of_day')
  @HiveField(6)
  final int numberOfDay;

  @JsonKey(name: 'color')
  @HiveField(7)
  int color;

  @JsonKey(name: 'display_name')
  @HiveField(8)
  final String displayName;

  /// 开始节数（范围 1-12）
  @JsonKey(name: 'start_section')
  @HiveField(9)
  final int? startSection;

  /// 结束节数（范围 1-12）
  @JsonKey(name: 'end_section')
  @HiveField(10)
  final int? endSection;

  /// 是否是自定义课程
  @JsonKey(name: 'is_custom')
  @HiveField(11)
  bool? isCustom;

  /// 课程所属的课程表容器 ID
  @JsonKey(name: 'container_id')
  @HiveField(12)
  String? containerId;

  /// 是否是考试（复用 isCustom 的显示逻辑）
  @JsonKey(name: 'is_exam')
  @HiveField(13)
  bool? isExam;

  Color getColor() {
    final customColors =
        CourseBox.get('customColors') as Map<dynamic, dynamic>?;

    if (hasCustomColor) {
      return Color(customColors![courseName] as int);
    }

    final colorMode = CourseBox.get('courseColorMode') as ColorMode?;
    switch (colorMode) {
      case null:
      case ColorMode.colorful:
        return Color(color);
      case ColorMode.palette:
        final palette = MTheme.courseTablePalette;
        if (palette != null && palette.isNotEmpty) {
          return getColorFromPaletteWithString(courseName, palette: palette)!;
        }
        return Color(color);
      case ColorMode.theme:
        final themeColor = CommonBox.get('themeColor') as int?;
        return Color(themeColor ?? color);
    }
  }

  bool get hasCustomColor {
    final customColors =
        CourseBox.get('customColors') as Map<dynamic, dynamic>?;
    return customColors != null && customColors.containsKey(courseName) == true;
  }

  factory CourseEntry.fromJson(Map<String, dynamic> json) =>
      _$CourseEntryFromJson(json);

  Map<String, dynamic> toJson() => _$CourseEntryToJson(this);

  @override
  String toString() {
    return '''CourseEntry(
      courseName: $courseName,
      displayName: $displayName,
      teacherName: ${teacherName.join(', ')},
      place: $place,
      weekday: $weekday,
      startWeek: $startWeek,
      endWeek: $endWeek,
      startSection: $startSection,
      endSection: $endSection,
      numberOfDay: $numberOfDay,
      color: 0x${color.toRadixString(16).toUpperCase()},
      isCustom: $isCustom,
      isExam: $isExam
    )''';
  }
}
