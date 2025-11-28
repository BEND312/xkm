import 'package:json_annotation/json_annotation.dart';
import 'package:swustmeow/entity/duifene/duifene_test_base.dart';

import 'duifene_course.dart';

part 'duifene_homework.g.dart';

@JsonSerializable()
class DuiFenEHomework extends DuiFenETestBase {
  const DuiFenEHomework({
    required super.course,
    required super.name,
    required super.endTime,
    required super.finished,
    required this.overdue,
  });

  final bool overdue;

  factory DuiFenEHomework.fromJson(Map<String, dynamic> json) =>
      _$DuiFenEHomeworkFromJson(json);
}
