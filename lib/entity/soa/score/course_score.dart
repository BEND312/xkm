import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:swustmeow/entity/soa/score/score_type.dart';

part 'course_score.g.dart';

@JsonSerializable()
@HiveType(typeId: 20)
class CourseScore {
  const CourseScore({
    required this.courseName,
    required this.courseId,
    required this.credit,
    required this.courseType,
    required this.formalScore,
    required this.resitScore,
    required this.points,
    required this.scoreType,
    required this.term,
  });

  /// 课程名
  @HiveField(0)
  final String courseName;

  /// 课程号（唯一课程ID）
  @HiveField(1)
  final String courseId;

  /// 学分
  @HiveField(2)
  final double credit;

  /// 课程性质
  ///
  /// 必修/任选/限选
  ///
  /// 当 [ScoreType] 为 [ScoreType.plan] 时本属性有效，否则为 `null`
  @HiveField(3)
  final String? courseType;

  /// 正考分数
  @HiveField(4)
  final String formalScore;

  /// 补考分数
  @HiveField(5)
  final String resitScore;

  /// 绩点
  ///
  /// 当缺考或不及格时为 `null`
  @HiveField(6)
  final double? points;

  /// 课程类别
  ///
  /// 详见 [ScoreType]
  @HiveField(7)
  final ScoreType scoreType;

  /// 学期
  @HiveField(8)
  final String term;

  factory CourseScore.fromJson(Map<String, dynamic> json) =>
      _$CourseScoreFromJson(json);
}
