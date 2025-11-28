import 'package:device_calendar/device_calendar.dart';

class SystemCalendar {
  const SystemCalendar(
      {required this.name, required this.id, required this.events});

  final String name;
  final String id;
  final List<Event> events;
}
