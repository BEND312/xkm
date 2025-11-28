import 'package:swustmeow/entity/soa/leave/daily_leave_options.dart';

class DailyLeaveDisplay {
  const DailyLeaveDisplay({
    required this.id,
    required this.time,
    required this.type,
    required this.address,
    required this.status,
    required this.leaveStatus,
  });

  final String id;
  final String time;
  final String type;
  final String address;
  final String status;
  final String leaveStatus;

  bool equalsTo(DailyLeaveOptions o) {
    return time == o.parseTime() &&
        type == o.leaveType.name &&
        address == o.outAddress;
  }
}
