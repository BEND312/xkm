import 'dart:async';
import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:swustmeow/utils/color.dart';
import 'package:swustmeow/widgets/entities/single_course.dart';
import 'package:swustmeow/widgets/today_courses/today_courses_widget_state.dart';

import '../../services/database/database_service.dart';
import '../../services/value_service.dart';
import '../../utils/courses.dart';

class TodayCoursesWidgetManager {
  final state = TodayCoursesWidgetState();

  TodayCoursesWidgetManager() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      updateState();
      await updateWidget();
      timer.cancel();
        });

    Timer.periodic(const Duration(seconds: 5), (_) async {
      updateState();
      await updateWidget();
    });
  }

  void updateState() {
    final now = DateTime.now();
    state.lastUpdateTimestamp.value = now.millisecondsSinceEpoch;
    final currentContainer = ValueService.currentCoursesContainer;

    if (currentContainer.value == null) {
      state.success.value = false;
      state.clear();
      return;
    }

    final currentTerm = currentContainer.value!.term;
    final (todayCourses, _, _) =
        getCourse(currentTerm, currentContainer.value!.entries);

    state.success.value = true;

    final (_, week) = getWeekNum(currentTerm, now);
    state.weekNum.value = week;
    state.todayCourses.value = todayCourses.map((entry) {
      final (time, _) = getCourseRemainingString(entry);
      return SingleCourse(
        name: entry.displayName != entry.courseName
            ? '${entry.displayName} - ${entry.courseName}'
            : entry.courseName,
        place: entry.place,
        time: time,
        color: entry.getColor().toInt().toString(),
      );
    }).toList();
  }

  Future<void> updateWidget() async {
    await DatabaseService.widgetsDatabaseService
        ?.update('today_courses_success', state.success.value);
    await DatabaseService.widgetsDatabaseService?.update(
        'today_courses_last_update_timestamp', state.lastUpdateTimestamp.value);
    await DatabaseService.widgetsDatabaseService?.update(
        'today_courses_today_courses_list',
        json.encode(state.todayCourses.value?.map((c) => c.toJson()).toList()));
    await DatabaseService.widgetsDatabaseService
        ?.update('today_courses_week_num', state.weekNum.value);

    await HomeWidget.updateWidget(
      qualifiedAndroidName:
          'store.swust.swustmeow.widgets.today_courses.TodayCoursesWidgetReceiver',
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName:
          'store.swust.swustmeow.widgets.today_courses.mini.TodayCoursesMiniWidgetReceiver',
    );
  }
}
