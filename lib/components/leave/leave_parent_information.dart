import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/utils/empty.dart';

import '../../entity/soa/leave/leave_value_provider.dart';
import '../../utils/widget.dart';

class LeaveParentInformation extends StatefulWidget {
  const LeaveParentInformation({super.key, required this.provider});

  final LeaveValueProvider provider;

  @override
  State<StatefulWidget> createState() => _LeaveParentInformationState();
}

class _LeaveParentInformationState extends State<LeaveParentInformation> {
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.provider.options != null) {
      _parentNameController.text = widget.provider.options!.jhrName;
      _parentPhoneController.text = widget.provider.options!.jhrPhone;
    }

    _parentNameController.addListener(() async {
      final value = _parentNameController.text;
      await widget.provider.setFieldValue('AllLeave1_JHRName', value);
      widget.provider.setTemplateValue('jhrName', value);
    });

    _parentPhoneController.addListener(() async {
      final value = _parentPhoneController.text;
      await widget.provider.setFieldValue('AllLeave1_JHRPhone', value);
      widget.provider.setTemplateValue('jhrPhone', value);
    });
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentPhoneController.dispose();
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
                Text('家长或监护人信息', style: widget.provider.ts),
                FTextField(
                  controller: _parentNameController,
                  maxLines: 1,
                  label: Text('姓名（选填）', style: widget.provider.ts2),
                  // hint: '姓名（选填）',
                  textInputAction: TextInputAction.next,
                ),
                FTextField(
                  controller: _parentPhoneController,
                  maxLines: 1,
                  label: Text('联系电话（选填）', style: widget.provider.ts2),
                  // hint: '联系电话（选填）',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          )
        : const Empty();
  }
}
