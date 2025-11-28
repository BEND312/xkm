import 'package:flutter/material.dart';
import 'package:forui/assets.dart';
import 'package:hive/hive.dart';
import 'package:swustmeow/data/m_theme.dart';

part 'activity_type.g.dart';

@HiveType(typeId: 5)
enum ActivityType {
  @HiveField(0)
  today,
  @HiveField(1)
  shift,
  @HiveField(2)
  common,
  @HiveField(3)
  festival,
  @HiveField(4)
  bigHoliday,
  @HiveField(5)
  hidden;
}

class ActivityTypeData {
  const ActivityTypeData(this.color, this.priority, this.icon);

  final Color color;
  final int priority;
  final SvgAsset? icon;

  factory ActivityTypeData.of(ActivityType type) => switch (type) {
        ActivityType.today => ActivityTypeData(
            MTheme.primary2,
            5,
            SvgAsset(
              'forui_assets',
              'circle',
              'assets/icons/circle.svg',
            )),
        ActivityType.shift => ActivityTypeData(
            Colors.red,
            4,
            SvgAsset(
              'forui_assets',
              'calendar-x',
              'assets/icons/calendar-x.svg',
            )),
        ActivityType.common => ActivityTypeData(
            Colors.orange,
            3,
            SvgAsset(
              'forui_assets',
              'square-chart-gantt',
              'assets/icons/square-chart-gantt.svg',
            )),
        ActivityType.festival => ActivityTypeData(
            Color(0xFF2E7D32),
            2,
            SvgAsset(
              'forui_assets',
              'calendar-fold',
              'assets/icons/calendar-fold.svg',
            )),
        ActivityType.bigHoliday => ActivityTypeData(
            Color(0xFF66BB6A),
            1,
            SvgAsset(
              'forui_assets',
              'sparkles',
              'assets/icons/sparkles.svg',
            )),
        ActivityType.hidden => ActivityTypeData(Colors.black, 0, null),
      };
}
