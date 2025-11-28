import 'package:hive/hive.dart';

part 'exam_type.g.dart';

@HiveType(typeId: 19)
enum ExamType {
  /// 期末考试
  @HiveField(0)
  finalExam,

  /// 期中考试
  @HiveField(1)
  midExam,

  /// 补考
  @HiveField(2)
  resitExam;
}
