import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/utils/time.dart';

import '../../entity/soa/leave/leave_value_provider.dart';
import '../../utils/widget.dart';

class LeaveTimeInformation extends StatefulWidget {
  const LeaveTimeInformation({super.key, required this.provider});

  final LeaveValueProvider provider;

  @override
  State<StatefulWidget> createState() => _LeaveTimeInformationState();
}

class _LeaveTimeInformationState extends State<LeaveTimeInformation> {
  FCalendarController<DateTime?>? _beginDateController;
  int _beginTime = 12;
  FCalendarController<DateTime?>? _endDateController;
  int _endTime = 12;

  @override
  void initState() {
    super.initState();

    final loadOptions =
        widget.provider.leaveId != null && widget.provider.options != null;
    final now = DateTime.now();

    setEndDateController() => _endDateController = FCalendarController.date(
        initialSelection:
            loadOptions ? widget.provider.options!.leaveEndDate : null,
        selectable: (dt) => dt >= (_beginDateController?.value ?? now))
      ..addValueListener((value) async {
        if (value == null) return;
        widget.provider
            .setValidatorMessage(_calculateDays() <= 0 ? '请假天数必须大于0' : null);
        await widget.provider.setFieldValue('AllLeave1_LeaveEndDate',
            '${value.year}-${value.month.padL2}-${value.day.padL2}');
        _refresh();
        await widget.provider.runJs('getDateDiff();');
      });

    _beginDateController = FCalendarController.date(
        initialSelection:
            loadOptions ? widget.provider.options!.leaveBeginDate : null,
        selectable: (dt) => dt <= (_endDateController?.value ?? now))
      ..addValueListener((value) async {
        if (value == null) return;
        widget.provider
            .setValidatorMessage(_calculateDays() <= 0 ? '请假天数必须大于0' : null);
        await widget.provider.setFieldValue('AllLeave1_LeaveBeginDate',
            '${value.year}-${value.month.padL2}-${value.day.padL2}');
        await widget.provider.runJs('getDateDiff();');
        _refresh(setEndDateController);
      });

    setEndDateController();

    if (loadOptions) {
      _beginTime = widget.provider.options!.leaveBeginTime ?? 12;
      _endTime = widget.provider.options!.leaveEndTime ?? 12;
    }
  }

  @override
  void dispose() {
    _beginDateController?.dispose();
    _endDateController?.dispose();
    super.dispose();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: joinGap(
        gap: 10,
        axis: Axis.vertical,
        widgets: [
          Row(
            children: [
              Text('请假时间', style: widget.provider.ts),
              Spacer(),
              Text('共${_calculateDays()}天',
                  style: widget.provider.ts.copyWith(fontSize: 14)),
            ],
          ),
          Row(
            children: joinGap(
              gap: 8,
              axis: Axis.horizontal,
              widgets: [
                Text('始', style: widget.provider.ts),
                Expanded(
                  flex: 4,
                  child:
                      widget.provider.buildLineCalendar(_beginDateController),
                ),
                Expanded(
                  flex: 1,
                  child: widget.provider.buildTimeSelector(
                    _beginTime,
                    (value) async {
                      await widget.provider.setSelectValue(
                          'AllLeave1_LeaveBeginTime', value.padL2);
                      _refresh(() => _beginTime = value);
                    },
                  ),
                )
              ],
            ),
          ),
          Row(
            children: joinGap(
              gap: 8,
              axis: Axis.horizontal,
              widgets: [
                Text('终', style: widget.provider.ts),
                Expanded(
                  flex: 4,
                  child: widget.provider.buildLineCalendar(_endDateController,
                      start: _beginDateController?.value),
                ),
                Expanded(
                  flex: 1,
                  child: widget.provider.buildTimeSelector(
                    _endTime,
                    (value) async {
                      await widget.provider.setSelectValue(
                          'AllLeave1_LeaveEndTime', value.padL2);
                      _refresh(() => _endTime = value);
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDays() {
    if (widget.provider.isLoading) return 0;

    final now = DateTime.now();
    final beginDate = _beginDateController?.value ?? now;
    final endDate = _endDateController?.value ?? now;
    final start =
        DateTime(beginDate.year, beginDate.month, beginDate.day, _beginTime);
    final end = DateTime(endDate.year, endDate.month, endDate.day, _endTime);
    final diff = end.difference(start);
    return (diff.inMilliseconds / 1000 / 60 / 60 / 24).abs().round();
  }
}
