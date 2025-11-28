import 'package:hive/hive.dart';

part 'optional_task_type.g.dart';

@HiveType(typeId: 14)
enum OptionalTaskType {
  /// 通选课
  @HiveField(0)
  commonTask('commonTask'),

  /// 体育课
  @HiveField(1)
  sportTask('sportTask');

  final String type;

  const OptionalTaskType(this.type);
}
