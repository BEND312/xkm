import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/utils/empty.dart';

import '../../entity/soa/leave/leave_value_provider.dart';
import '../../utils/widget.dart';

class LeaveSelfInformation extends StatefulWidget {
  const LeaveSelfInformation({super.key, required this.provider});

  final LeaveValueProvider provider;

  @override
  State<StatefulWidget> createState() => _LeaveSelfInformationState();
}

class _LeaveSelfInformationState extends State<LeaveSelfInformation> {
  final _selfPhoneController = TextEditingController();
  final _selfOtherTelController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.provider.options != null) {
      _selfPhoneController.text = widget.provider.options!.stuMoveTel;
      _selfOtherTelController.text = widget.provider.options!.stuOtherTel;
    }

    _selfPhoneController.addListener(() async {
      final value = _selfPhoneController.text;
      await widget.provider.setFieldValue('AllLeave1_StuMoveTel', value);
      widget.provider.setTemplateValue('stuMoveTel', value);
    });

    _selfOtherTelController.addListener(() async {
      final value = _selfOtherTelController.text;
      await widget.provider.setFieldValue('AllLeave1_StuOtherTel', value);
      widget.provider.setTemplateValue('stuOtherTel', value);
    });
  }

  @override
  void dispose() {
    _selfPhoneController.dispose();
    _selfOtherTelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !widget.provider.showRequiredOnly
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: joinGap(
              gap: 10,
              axis: Axis.vertical,
              widgets: [
                Text('本人联系方式', style: widget.provider.ts),
                FTextField(
                  controller: _selfPhoneController,
                  maxLines: 1,
                  label: Text('本人电话（选填）', style: widget.provider.ts2),
                  // hint: '本人电话（选填）',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                FTextField(
                  controller: _selfOtherTelController,
                  maxLines: 1,
                  label: Text('其他联系方式（选填）', style: widget.provider.ts2),
                  // hint: '其他联系方式（选填）',
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          )
        : const Empty();
  }
}
