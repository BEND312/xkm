import 'duifene_course.dart';

abstract class DuiFenETestBase {
  const DuiFenETestBase({
    required this.course,
    required this.name,
    this.beginTime,
    required this.endTime,
    required this.finished,
  });

  final DuiFenECourse course;
  final String name;
  final DateTime? beginTime;
  final DateTime endTime;
  final bool finished;
}
