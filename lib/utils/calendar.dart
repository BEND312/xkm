import 'package:device_calendar/device_calendar.dart';
import 'package:swustmeow/data/values.dart';
import 'package:swustmeow/entity/calendar_event.dart';
import 'package:swustmeow/entity/system_calendar.dart';
import 'package:swustmeow/utils/status.dart';

final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

Future<StatusContainer<dynamic>> _checkPermission() async {
  final permissionGranted = await _deviceCalendarPlugin.hasPermissions();
  if (!permissionGranted.isSuccess || !permissionGranted.data!) {
    final result = await _deviceCalendarPlugin.requestPermissions();
    if (!result.isSuccess || !result.data!) {
      return const StatusContainer(Status.notAuthorized);
    }
  }
  return const StatusContainer(Status.ok);
}

Future<StatusContainer<List<SystemCalendar>>> fetchAllSystemCalendars() async {
  final p = await _checkPermission();
  if (p.status != Status.ok) return p as StatusContainer<List<SystemCalendar>>;

  final calendarResult = await _deviceCalendarPlugin.retrieveCalendars();
  if (!calendarResult.isSuccess) {
    return const StatusContainer(Status.fail);
  }

  final calendars = (await _deviceCalendarPlugin.retrieveCalendars())
          .data
          ?.toList()
          .where((c) => c.name?.trim() == Values.name)
          .toList() ??
      [];
  final lastCalendar = calendars.lastOrNull;

  // 删除多余的日历
  if (calendars.length > 1) {
    for (final calendar in calendars) {
      if (calendar.id == null) continue;
      if (calendar.id == lastCalendar!.id) continue;
      await _deviceCalendarPlugin.deleteCalendar(calendar.id!);
    }
  }

  final calendarResult2 = await _deviceCalendarPlugin.retrieveCalendars();
  if (!calendarResult2.isSuccess) {
    return const StatusContainer(Status.fail);
  }

  final List<SystemCalendar> result = [];
  for (final calendar in calendarResult2.data!) {
    final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
      calendar.id,
      RetrieveEventsParams(
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now().add(
          const Duration(days: 365),
        ),
      ),
    );

    if (eventsResult.isSuccess && eventsResult.data != null) {
      result.add(
        SystemCalendar(
          name: calendar.name!,
          id: calendar.id!,
          events: eventsResult.data!,
        ),
      );
    }
  }

  return StatusContainer(Status.ok, result);
}

List<CalendarEvent>? getEventsMatched(
        List<CalendarEvent>? list, DateTime date) =>
    list?.where((ev) => ev.isInEvent(date)).toList();
