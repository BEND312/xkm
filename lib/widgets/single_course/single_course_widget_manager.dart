import 'dart:async';
import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:swustmeow/services/value_service.dart';
import 'package:swustmeow/utils/color.dart';
import 'package:swustmeow/widgets/entities/single_course.dart';
import 'package:swustmeow/widgets/single_course/single_course_widget_state.dart';

import '../../services/database/database_service.dart';
import '../../utils/courses.dart';

class SingleCourseWidgetManager {
  final state = SingleCourseWidgetState();

  SingleCourseWidgetManager() {
    updateState();
    updateWidget();
    Timer.periodic(const Duration(milliseconds: 1000), (_) async {
      updateState();
      await updateWidget();
    });
  }

  void updateState() {
    final now = DateTime.now();
    state.lastUpdateTimestamp.value = now.millisecondsSinceEpoch;
    final currentContainer = ValueService.currentCoursesContainer;
    final entries = currentContainer.value?.entries;

    if (currentContainer.value == null || entries == null) {
      state.success.value = false;
      state.clear();
      return;
    }

    final currentTerm = currentContainer.value!.term;
    final (_, current, next) = getCourse(currentTerm, entries);
    state.success.value = true;

    final (_, week) = getWeekNum(currentTerm, now);
    state.weekNum.value = week;

    final (currentTime, _) =
        current == null ? (null, null) : getCourseRemainingString(current);
    state.current.value = current == null
        ? null
        : SingleCourse(
            name: current.courseName,
            place: current.place,
            time: currentTime!,
            color: current.getColor().toInt().toString(),
          );

    final (nextTime, nextDiff) =
        next == null ? (null, null) : getCourseRemainingString(next);
    state.next.value = next == null
        ? null
        : SingleCourse(
            name: next.courseName,
            place: next.place,
            time: nextTime!,
            diff: nextDiff!,
            color: next.getColor().toInt().toString(),
          );
  }

  Future<void> updateWidget() async {
    await DatabaseService.widgetsDatabaseService
        ?.update('single_course_success', state.success.value);
    await DatabaseService.widgetsDatabaseService?.update(
        'single_course_last_update_timestamp', state.lastUpdateTimestamp.value);
    await DatabaseService.widgetsDatabaseService?.update(
        'single_course_current_course_json',
        json.encode(state.current.value?.toJson()));
    await DatabaseService.widgetsDatabaseService?.update(
        'single_course_next_course_json',
        json.encode(state.next.value?.toJson()));
    await DatabaseService.widgetsDatabaseService
        ?.update('single_course_week_num', state.weekNum.value);

    await HomeWidget.updateWidget(
      qualifiedAndroidName:
          'store.swust.swustmeow.widgets.single_course.SingleCourseWidgetReceiver',
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName:
          'store.swust.swustmeow.widgets.single_course.mini.SingleCourseMiniWidgetReceiver',
    );
  }
}
