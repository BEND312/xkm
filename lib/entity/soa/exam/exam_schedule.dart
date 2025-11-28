import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:swustmeow/entity/soa/exam/exam_type.dart';

import '../../../data/values.dart';
import '../../../utils/time.dart';

part 'exam_schedule.g.dart';

@JsonSerializable()
@HiveType(typeId: 18)
class ExamSchedule {
  const ExamSchedule({
    required this.type,
    required this.courseName,
    required this.weekNum,
    required this.numberOfDay,
    required this.weekday,
    required this.date,
    required this.place,
    required this.classroom,
    required this.seatNo,
  });

  @HiveField(0)
  final ExamType type;
  @HiveField(1)
  final String courseName;
  @HiveField(2)
  final int weekNum;
  @HiveField(3)
  final int numberOfDay;
  @HiveField(4)
  final int weekday;
  @HiveField(5)
  final DateTime date;
  @HiveField(6)
  final String place;
  @HiveField(7)
  final String classroom;
  @HiveField(8)
  final int seatNo;

  bool get isActive {
    final now = DateTime.now();
    final time = Values.courseTableTimes[numberOfDay - 1];
    final timePassed =
        hmAfter('${now.hour}:${now.minute}', time.split('\n').last);
    return (now < date) || (now == date && !timePassed);
  }

  factory ExamSchedule.fromJson(Map<String, dynamic> json) =>
      _$ExamScheduleFromJson(json);
}
