import 'package:json_annotation/json_annotation.dart';
import 'package:swustmeow/entity/duifene/duifene_course.dart';
import 'package:swustmeow/entity/duifene/duifene_test_base.dart';

part 'duifene_test.g.dart';

@JsonSerializable()
class DuiFenETest extends DuiFenETestBase {
  const DuiFenETest({
    required super.course,
    required super.name,
    required this.createTime,
    required super.beginTime,
    required super.endTime,
    required this.submitTime,
    required this.limitMinutes,
    required this.creatorName,
    required this.score,
    required super.finished,
    required this.overdue,
  });

  final DateTime createTime;
  final DateTime? submitTime;
  final int limitMinutes;
  final String creatorName;
  final int score;
  final bool overdue;

  factory DuiFenETest.fromJson(Map<String, dynamic> json) =>
      _$DuiFenETestFromJson(json);
}
