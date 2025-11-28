import 'package:json_annotation/json_annotation.dart';

part 'single_course.g.dart';

@JsonSerializable()
class SingleCourse {
  final String name;
  final String place;
  final String time;
  final String diff;
  final String color;

  SingleCourse({
    required this.name,
    required this.place,
    required this.time,
    this.diff = '',
    required this.color,
  });

  factory SingleCourse.fromJson(Map<String, dynamic> json) =>
      _$SingleCourseFromJson(json);

  Map<String, dynamic> toJson() => _$SingleCourseToJson(this);
}
