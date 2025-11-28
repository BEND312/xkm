import 'package:hive/hive.dart';

part 'term_date.g.dart';

@HiveType(typeId: 11)
class TermDate {
  const TermDate({required this.start, required this.end, required this.weeks});

  @HiveField(0)
  final DateTime start;

  @HiveField(1)
  final DateTime end;

  @HiveField(2)
  final int weeks;

  (DateTime, DateTime, int) get value => (start, end, weeks);
}
