import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/utils/time.dart';

import '../../entity/soa/leave/leave_value_provider.dart';
import '../../entity/soa/leave/vehicle_type.dart';
import '../../utils/widget.dart';

class LeaveGoBackInformation extends StatefulWidget {
  const LeaveGoBackInformation({super.key, required this.provider});

  final LeaveValueProvider provider;

  @override
  State<StatefulWidget> createState() => _LeaveGoBackInformationState();
}

class _LeaveGoBackInformationState extends State<LeaveGoBackInformation> {
  FCalendarController<DateTime?>? _goDateController;
  int _goTime = 12;
  final _goVehicleTypeController =
      FRadioSelectGroupController<VehicleType>(value: VehicleType.car);
  FCalendarController<DateTime?>? _backDateController;
  int _backTime = 12;
  final _backVehicleTypeController =
      FRadioSelectGroupController<VehicleType>(value: VehicleType.car);

  @override
  void initState() {
    super.initState();

    final loadOptions =
        widget.provider.leaveId != null && widget.provider.options != null;
    final now = DateTime.now();

    setBackDateController() => _backDateController = FCalendarController.date(
        initialSelection:
            loadOptions ? widget.provider.options!.backDate : null,
        selectable: (dt) => dt >= (_goDateController?.value ?? now))
      ..addValueListener((value) async {
        if (value == null) return;
        await widget.provider.setFieldValue('AllLeave1_GoDate',
            '${value.year}-${value.month.padL2}-${value.day.padL2}');
        _refresh();
      });

    _goDateController = FCalendarController.date(
        initialSelection: loadOptions ? widget.provider.options!.goDate : null,
        selectable: (dt) => dt <= (_backDateController?.value ?? now))
      ..addValueListener((value) async {
        if (value == null) return;
        await widget.provider.setFieldValue('AllLeave1_BackDate',
            '${value.year}-${value.month.padL2}-${value.day.padL2}');
        _refresh(setBackDateController);
      });

    setBackDateController();

    if (loadOptions) {
      _goTime = widget.provider.options!.goTime ?? 12;
      _goVehicleTypeController.update(widget.provider.options!.goVehicle,
          selected: true);

      _backTime = widget.provider.options!.backTime ?? 12;
      _backVehicleTypeController.update(widget.provider.options!.backVehicle,
          selected: true);
    }

    _goVehicleTypeController.addValueListener((values) async {
      final value = values.firstOrNull;
      if (value == null) return;
      final name = VehicleTypeData.from(value).name;
      await widget.provider.setTableCheckValue('AllLeave1_GoVehicle', name);
      widget.provider.setTemplateValue('goVehicle', value.name);
    });

    _backVehicleTypeController.addValueListener((values) async {
      final value = values.firstOrNull;
      if (value == null) return;
      final name = VehicleTypeData.from(value).name;
      await widget.provider.setTableCheckValue('AllLeave1_BackVehicle', name);
      widget.provider.setTemplateValue('backVehicle', value.name);
    });
  }

  @override
  void dispose() {
    _goDateController?.dispose();
    _goVehicleTypeController.dispose();
    _backDateController?.dispose();
    _backVehicleTypeController.dispose();
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
          Text('往返时间', style: widget.provider.ts),
          _buildRow(
            '往',
            _goDateController,
            _goTime,
            (value) async {
              await widget.provider
                  .setSelectValue('AllLeave1_GoTime', value.padL2);
              _refresh(() => _goTime = value);
            },
            _goVehicleTypeController,
          ),
          _buildRow(
            '返',
            _backDateController,
            _backTime,
            (value) async {
              await widget.provider
                  .setSelectValue('AllLeave1_BackTime', value.padL2);
              _refresh(() => _backTime = value);
            },
            _backVehicleTypeController,
          )
        ],
      ),
    );
  }

  Widget _buildRow(
    String text,
    FCalendarController<DateTime?>? dateController,
    int time,
    Function(int value) onTimeChange,
    FRadioSelectGroupController<VehicleType> vehicleController,
  ) {
    return Row(
      children: joinGap(
        gap: 8,
        axis: Axis.horizontal,
        widgets: [
          Text(text, style: widget.provider.ts),
          Expanded(
            flex: 8,
            child: Column(
              children: joinGap(
                gap: 8,
                axis: Axis.vertical,
                widgets: [
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child:
                            widget.provider.buildLineCalendar(dateController),
                      ),
                      Expanded(
                        flex: 1,
                        child: widget.provider
                            .buildTimeSelector(time, onTimeChange),
                      )
                    ],
                  ),
                  SizedBox(
                    width: 290,
                    child: FSelectMenuTile.builder(
                      groupController: vehicleController,
                      scrollController: ScrollController(),
                      menuAnchor: Alignment.bottomRight,
                      tileAnchor: Alignment.topRight,
                      count: VehicleType.values.length,
                      maxHeight: 200,
                      menuTileBuilder: (context, index) {
                        final type = VehicleType.values[index];
                        final data = VehicleTypeData.from(type);
                        return FSelectTile(
                          title: Text(data.name),
                          value: type,
                          suffixIcon: FIcon(data.icon),
                        );
                      },
                      title: Text('交通工具', style: widget.provider.ts),
                      details: ListenableBuilder(
                        listenable: vehicleController,
                        builder: (context, _) => Text(VehicleTypeData.from(
                                (vehicleController.value.firstOrNull ??
                                    VehicleType.car))
                            .name),
                      ),
                      autoHide: true,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
