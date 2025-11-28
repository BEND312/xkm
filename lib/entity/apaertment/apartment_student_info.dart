import 'package:hive/hive.dart';

part 'apartment_student_info.g.dart';

@HiveType(typeId: 22)
class ApartmentStudentInfo {
  const ApartmentStudentInfo({
    required this.roomName,
    required this.bed,
    required this.className,
    required this.facultyName,
    required this.grade,
    required this.isCheckIn,
    required this.realName,
    required this.studentNumber,
    required this.studentTypeName,
  });

  /// 房间号，格式：西5-404
  @HiveField(0)
  final String roomName;

  /// 床位号
  @HiveField(1)
  final int bed;

  /// 班级名称
  @HiveField(2)
  final String className;

  /// 学院名称
  @HiveField(3)
  final String facultyName;

  /// 年级，如2024
  @HiveField(4)
  final int grade;

  /// 是否已报道
  @HiveField(5)
  final bool isCheckIn;

  /// 姓名
  @HiveField(6)
  final String realName;

  /// 学号
  @HiveField(7)
  final String studentNumber;

  /// 学生类型，如本科生
  @HiveField(8)
  final String studentTypeName;
}
