import 'dart:async';
import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:swustmeow/utils/time.dart';
import 'package:swustmeow/widgets/course_table/course_table_widget_state.dart';

import '../../data/values.dart';
import '../../services/database/database_service.dart';
import '../../services/global_service.dart';
import '../../services/value_service.dart';
import '../../utils/courses.dart';

class CourseTableWidgetManager {
  final state = CourseTableWidgetState();

  CourseTableWidgetManager() {
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
    final currentContainer = ValueService.currentCoursesContainer;

    if (currentContainer.value == null) {
      state.success.value = false;
      state.clear();
      return;
    }

    final now = DateTime.now();
    state.lastUpdateTimestamp.value = now.millisecondsSinceEpoch;
    state.success.value = true;

    final currentTerm = currentContainer.value!.term;
    final (_, week) = getWeekNum(currentTerm, now);
    state.weekNum.value = week;

    state.entries.value = currentContainer.value!.entries;

    final (start, _, _) = GlobalService.termDates.value[currentTerm]?.value ??
        Values.getFallbackTermDates(currentTerm);
    state.termStartDate.value = start;

    state.courseTableTimes.value = Values.courseTableTimes;
    state.term.value = currentContainer.value!.term;
  }

  Future<void> updateWidget() async {
    await DatabaseService.widgetsDatabaseService
        ?.update('course_table_success', state.success.value);
    await DatabaseService.widgetsDatabaseService?.update(
        'course_table_last_update_timestamp', state.lastUpdateTimestamp.value);
    await DatabaseService.widgetsDatabaseService
        ?.update('course_table_week_num', state.weekNum.value);
    await DatabaseService.widgetsDatabaseService?.update(
        'course_table_entries_json',
        json.encode(state.entries.value?.map((e) => e.toJson()).toList()));
    await DatabaseService.widgetsDatabaseService?.update(
        'course_table_term_start_date', state.termStartDate.value.ymdString);
    await DatabaseService.widgetsDatabaseService?.update(
        'course_table_times_json', json.encode(state.courseTableTimes.value));
    await DatabaseService.widgetsDatabaseService
        ?.update('course_table_term', state.term.value);

    await HomeWidget.updateWidget(
      qualifiedAndroidName:
          'store.swust.swustmeow.widgets.course_table.CourseTableWidgetReceiver',
    );
  }
}
