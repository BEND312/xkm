import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/utils/text.dart';

import '../../entity/soa/leave/leave_value_provider.dart';
import '../../utils/widget.dart';

class LeaveOutInformation extends StatefulWidget {
  const LeaveOutInformation({super.key, required this.provider});

  final LeaveValueProvider provider;

  @override
  State<StatefulWidget> createState() => _LeaveOutInformationState();
}

class _LeaveOutInformationState extends State<LeaveOutInformation> {
  final _outTelController = TextEditingController();
  final _outPhoneController = TextEditingController();
  final _outRelationController = TextEditingController();
  final _outNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.provider.options != null) {
      _outTelController.text = widget.provider.options!.outTel;
      _outPhoneController.text = widget.provider.options!.outMoveTel;
      _outRelationController.text = widget.provider.options!.relation;
      _outNameController.text = widget.provider.options!.outName;
    }

    _outTelController.addListener(() async {
      final value = _outTelController.text;
      await widget.provider.setFieldValue('AllLeave1_OutTel', value);
      widget.provider.setTemplateValue('outTel', value);
    });

    _outPhoneController.addListener(() async {
      final value = _outPhoneController.text;
      await widget.provider.setFieldValue('AllLeave1_OutMoveTel', value);
      widget.provider.setTemplateValue('outMoveTel', value);
    });

    _outRelationController.addListener(() async {
      final value = _outRelationController.text;
      await widget.provider.setFieldValue('AllLeave1_Relation', value);
      widget.provider.setTemplateValue('relation', value);
    });

    _outNameController.addListener(() async {
      final value = _outNameController.text;
      await widget.provider.setFieldValue('AllLeave1_OutName', value);
      widget.provider.setTemplateValue('outName', value);
    });
  }

  @override
  void dispose() {
    _outTelController.dispose();
    _outPhoneController.dispose();
    _outRelationController.dispose();
    _outNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: joinGap(
        gap: 10,
        axis: Axis.vertical,
        widgets: [
          Text('外出联系人信息', style: widget.provider.ts),
          Row(
            children: joinGap(
              gap: 8,
              axis: Axis.horizontal,
              widgets: [
                Expanded(
                  child: FTextField(
                    controller: _outNameController,
                    maxLines: 1,
                    label: Text('联系人姓名（必填）', style: widget.provider.ts2),
                    // hint: '联系人姓名（必填）',
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) =>
                        (value?.isContentEmpty ?? true) ? '不可为空' : null,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Expanded(
                  child: FTextField(
                    controller: _outRelationController,
                    maxLines: 1,
                    label: Text('与本人关系（必填）', style: widget.provider.ts2),
                    // hint: '与本人关系（必填）',
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) =>
                        (value?.isContentEmpty ?? true) ? '不可为空' : null,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
          ),
          FTextField(
            controller: _outTelController,
            maxLines: 1,
            label: Text('固定电话（必填，无电话可填“无”）', style: widget.provider.ts2),
            // hint: '固定电话（必填，无电话可填“无”）',
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                (value?.isContentEmpty ?? true) ? '不可为空，如无电话请填“无”' : null,
            textInputAction: TextInputAction.next,
          ),
          FTextField(
            controller: _outPhoneController,
            maxLines: 1,
            label: Text('移动电话（必填）', style: widget.provider.ts2),
            // hint: '移动电话（必填）',
            keyboardType: TextInputType.phone,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                (value?.isContentEmpty ?? true) ? '不可为空' : null,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
