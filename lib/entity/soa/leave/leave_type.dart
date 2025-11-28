import 'package:forui/forui.dart';
import 'package:hive/hive.dart';

part 'leave_type.g.dart';

@HiveType(typeId: 17)
enum LeaveType {
  @HiveField(0)
  seekJob,
  @HiveField(1)
  intern,
  @HiveField(2)
  returnHome,
  @HiveField(3)
  train,
  @HiveField(4)
  trip,
  @HiveField(5)
  sickLeave,
  @HiveField(6)
  personalLeave;

  factory LeaveType.from(String name) =>
      LeaveType.values.singleWhere((t) => LeaveTypeData.from(t).name == name);
}

class LeaveTypeData {
  const LeaveTypeData(this.name, this.icon);

  final String name;
  final SvgAsset icon;

  factory LeaveTypeData.from(LeaveType type) => switch (type) {
        LeaveType.seekJob => LeaveTypeData(
            '求职',
            SvgAsset(
              'forui_assets',
              'briefcase-business',
              'assets/icons/briefcase-business.svg',
            )),
        LeaveType.intern => LeaveTypeData(
            '实习',
            SvgAsset(
              'forui_assets',
              'contact',
              'assets/icons/contact.svg',
            )),
        LeaveType.returnHome => LeaveTypeData(
            '返家',
            SvgAsset(
              'forui_assets',
              'house',
              'assets/icons/house.svg',
            )),
        LeaveType.train => LeaveTypeData(
            '培训',
            SvgAsset(
              'forui_assets',
              'tv',
              'assets/icons/tv.svg',
            )),
        LeaveType.trip => LeaveTypeData(
            '旅游',
            SvgAsset(
              'forui_assets',
              'tree-palm',
              'assets/icons/tree-palm.svg',
            )),
        LeaveType.sickLeave => LeaveTypeData(
            '病假',
            SvgAsset(
              'forui_assets',
              'pill',
              'assets/icons/pill.svg',
            )),
        LeaveType.personalLeave => LeaveTypeData(
            '事假',
            SvgAsset(
              'forui_assets',
              'notepad-text',
              'assets/icons/notepad-text.svg',
            ))
      };
}
