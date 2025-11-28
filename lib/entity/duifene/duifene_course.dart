import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'duifene_course.g.dart';

@JsonSerializable()
@HiveType(typeId: 7)
class DuiFenECourse {
  DuiFenECourse({
    required this.courseName,
    required this.courseId,
    required this.tClassId,
    this.courseMatched,
  });

  @JsonKey(name: 'CourseName')
  @HiveField(0)
  final String courseName;

  @JsonKey(name: 'CourseID')
  @HiveField(1)
  final String courseId;

  @JsonKey(name: 'TClassID')
  @HiveField(2)
  final String tClassId;

  @HiveField(3)
  String? courseMatched;

  factory DuiFenECourse.fromJson(Map<String, dynamic> json) =>
      _$DuiFenECourseFromJson(json);

  Map<String, dynamic> toJson() => _$DuiFenECourseToJson(this);
}
