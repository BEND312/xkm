import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'daily_leave_options.dart';

typedef Setter = Future<void> Function(String id, String value);

class LeaveValueProvider {
  const LeaveValueProvider({
    required this.leaveId,
    required this.isLoading,
    required this.options,
    required this.ts,
    required this.ts2,
    required this.showRequiredOnly,
    required this.buildLineCalendar,
    required this.buildTimeSelector,
    required this.runJs,
    required this.setFieldValue,
    required this.setSelectValue,
    required this.setTableCheckValue,
    required this.setSpanCheckValue,
    required this.setValidatorMessage,
    required this.setTemplateValue,
  });

  final String? leaveId;
  final bool isLoading;
  final DailyLeaveOptions? options;
  final TextStyle ts;
  final TextStyle ts2;
  final bool showRequiredOnly;
  final Widget Function(FCalendarController<DateTime?>? controller,
      {DateTime? start}) buildLineCalendar;
  final Widget Function(int value, void Function(int) onChange)
      buildTimeSelector;
  final Future<void> Function(String source) runJs;
  final Setter setFieldValue;
  final Setter setSelectValue;
  final Setter setTableCheckValue;
  final Setter setSpanCheckValue;
  final void Function(String? message) setValidatorMessage;
  final void Function(String key, dynamic value) setTemplateValue;
}
