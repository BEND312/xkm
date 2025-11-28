import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../entity/soa/leave/leave_type.dart';
import '../../entity/soa/leave/leave_value_provider.dart';
import '../../utils/text.dart';
import '../../utils/widget.dart';

class LeaveThingInformation extends StatefulWidget {
  const LeaveThingInformation({super.key, required this.provider});

  final LeaveValueProvider provider;

  @override
  State<StatefulWidget> createState() => _LeaveThingInformationState();
}

class _LeaveThingInformationState extends State<LeaveThingInformation> {
  final _typeSelectController =
      FRadioSelectGroupController<LeaveType>(value: LeaveType.seekJob);
  final _thingController = TextEditingController();
  bool _tellParent = false;
  final _alongWithNumController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.provider.options != null) {
      _typeSelectController.update(widget.provider.options!.leaveType,
          selected: true);
      _thingController.text = widget.provider.options!.leaveThing;
      _tellParent = widget.provider.options!.isTellRbl;
      _alongWithNumController.text =
          widget.provider.options!.withNumNo.toString();
    }

    _typeSelectController.addValueListener((values) async {
      final value = values.firstOrNull;
      if (value == null) return;
      final name = LeaveTypeData.from(value).name;
      await widget.provider.setTableCheckValue('AllLeave1_LeaveType', name);
      widget.provider.setTemplateValue('leaveType', value.name);
    });

    _thingController.addListener(() async {
      final value = _thingController.text;
      await widget.provider.setFieldValue('AllLeave1_LeaveThing', value);
      widget.provider.setTemplateValue('leaveThing', value);
    });

    _alongWithNumController.addListener(() async {
      final value = _alongWithNumController.text;
      final result = _alongWithNumValidator(value);
      if (result != null) return;
      await widget.provider.setSelectValue('AllLeave1_WithNumNo', value);
      widget.provider.setTemplateValue('withNumNo', int.tryParse(value) ?? 0);
    });
  }

  @override
  void dispose() {
    _typeSelectController.dispose();
    _thingController.dispose();
    _alongWithNumController.dispose();
    super.dispose();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  String? _alongWithNumValidator(String? value) {
    if (value == null || value.isContentEmpty) return '不可为空';
    if (!numberOnly(value)) return '只能输入数字';
    int v = int.parse(value);
    if (v < 0) return '不得小于0人';
    if (v > 30) return '不得大于30人';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: joinGap(
        gap: 10,
        axis: Axis.vertical,
        widgets: [
          FSelectMenuTile.builder(
            groupController: _typeSelectController,
            scrollController: ScrollController(),
            // label: Text('请假事由类型', style: ts),
            count: LeaveType.values.length,
            maxHeight: 200,
            menuTileBuilder: (context, index) {
              final type = LeaveType.values[index];
              final data = LeaveTypeData.from(type);
              return FSelectTile(
                title: Text(data.name),
                value: type,
                suffixIcon: FIcon(data.icon),
              );
            },
            title: Text('请假事由类型', style: widget.provider.ts),
            details: ListenableBuilder(
              listenable: _typeSelectController,
              builder: (context, _) => Text(LeaveTypeData.from(
                      (_typeSelectController.value.firstOrNull ??
                          LeaveType.seekJob))
                  .name),
            ),
            autoHide: true,
          ),
          if (!widget.provider.showRequiredOnly)
            FTextField.multiline(
              controller: _thingController,
              maxLines: 4,
              label: Text('请假事由（选填）', style: widget.provider.ts2),
              // hint: '详细的请假事由（选填）',
              textInputAction: TextInputAction.next,
            ),
          Row(
            children: joinGap(
              gap: 8,
              axis: Axis.horizontal,
              widgets: [
                Expanded(
                    child: FCheckbox(
                  label: Text('已告知家长', style: widget.provider.ts),
                  value: _tellParent,
                  onChange: (value) async {
                    await widget.provider.setSpanCheckValue(
                        'AllLeave1_IsTellRbl', value ? '1' : '0');
                    widget.provider.setTemplateValue('isTellRbl', value);
                    _refresh(() => _tellParent = value);
                  },
                )),
                Expanded(
                  child: FTextField(
                    controller: _alongWithNumController,
                    maxLines: 1,
                    label: Text('同行人数（必填）', style: widget.provider.ts2),
                    // hint: '同行人数（必填）',
                    keyboardType: TextInputType.number,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _alongWithNumValidator,
                    textInputAction: TextInputAction.done,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
