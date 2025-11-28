import 'package:hive/hive.dart';

part 'points_data.g.dart';

@HiveType(typeId: 24)
class PointsData {
  const PointsData({
    required this.totalCredits,
    required this.requiredCoursesCredits,
    required this.averagePoints,
    required this.requiredCoursesPoints,
    required this.degreeCoursesPoints,
  });

  /// 总学分
  @HiveField(0)
  final double? totalCredits;

  /// 必修课（总）学分
  @HiveField(1)
  final double? requiredCoursesCredits;

  /// 平均绩点
  @HiveField(2)
  final double? averagePoints;

  /// 必修课（平均）绩点
  @HiveField(3)
  final double? requiredCoursesPoints;

  /// 学位课（平均）绩点
  @HiveField(4)
  final double? degreeCoursesPoints;
}
