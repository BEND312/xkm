import 'package:json_annotation/json_annotation.dart';

part 'chaoxing_course.g.dart';

@JsonSerializable()
class ChaoXingCourse {
  @JsonKey(name: 'course_name')
  final String courseName;

  @JsonKey(name: 'teacher_name')
  final String teacherName;

  @JsonKey(name: 'course_id')
  final int courseId;

  @JsonKey(name: 'class_id')
  final int classId;

  @JsonKey(name: 'cpi')
  final int cpi;

  const ChaoXingCourse({
    required this.courseName,
    required this.teacherName,
    required this.courseId,
    required this.classId,
    required this.cpi,
  });

  factory ChaoXingCourse.fromJson(Map<String, dynamic> json) =>
      _$ChaoXingCourseFromJson(json);

  @override
  String toString() {
    return 'ChaoXingCourse(teacherName: $teacherName, courseName: $courseName, courseId: $courseId, classId: $classId, cpi: $cpi)';
  }
}
