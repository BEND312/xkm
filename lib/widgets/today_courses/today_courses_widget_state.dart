import 'package:flutter/cupertino.dart';

import '../entities/single_course.dart';

class TodayCoursesWidgetState {
  final success = ValueNotifier(true);
  final lastUpdateTimestamp =
      ValueNotifier(DateTime.now().millisecondsSinceEpoch);
  final todayCourses = ValueNotifier<List<SingleCourse>?>(null);
  final weekNum = ValueNotifier<int>(0);

  void clear() {
    todayCourses.value = null;
    weekNum.value = 0;
  }
}
