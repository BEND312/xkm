import 'package:swustmeow/entity/date_type.dart';

abstract class BaseEvent {
  const BaseEvent();

  String? getName();

  DateTime? getStart(DateTime date);

  DateTime? getEnd(DateTime date);

  DateType getType(DateTime date);
}
