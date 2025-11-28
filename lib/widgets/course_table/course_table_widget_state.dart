import 'package:flutter/cupertino.dart';
import 'package:swustmeow/entity/soa/course/course_entry.dart';

class CourseTableWidgetState {
  final success = ValueNotifier(true);
  final lastUpdateTimestamp =
      ValueNotifier(DateTime.now().millisecondsSinceEpoch);
  final weekNum = ValueNotifier(0);
  final entries = ValueNotifier<List<CourseEntry>?>(null);
  final termStartDate = ValueNotifier<DateTime>(DateTime.now());
  final courseTableTimes = ValueNotifier<List<String>>([]);
  final term = ValueNotifier<String>('');

  void clear() {
    entries.value = null;
  }
}
