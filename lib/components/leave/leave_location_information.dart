import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/utils/text.dart';
import 'package:swustmeow/utils/time.dart';

import '../../data/soa_leave_area.dart';
import '../../entity/soa/leave/daily_leave_options.dart';
import '../../entity/soa/leave/leave_value_provider.dart';
import '../../utils/widget.dart';
import '../utils/empty.dart';

class LeaveLocationInformation extends StatefulWidget {
  const LeaveLocationInformation({super.key, required this.provider});

  final LeaveValueProvider provider;

  @override
  State<StatefulWidget> createState() => _LeaveLocationInformationState();
}

class _LeaveLocationInformationState extends State<LeaveLocationInformation> {
  final Map<int, String> _provinces = {};
  final Map<int, String> _cities = {};
  final Map<int, String> _counties = {};
  final _provinceSelectController = FRadioSelectGroupController<int>();
  final _citySelectController = FRadioSelectGroupController<int>();
  final _countySelectController = FRadioSelectGroupController<int>();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.provider.options != null) {
      _loadArea(widget.provider.options!);
      _addressController.text = widget.provider.options!.outAddress;
    }

    _loadProvinces();

    _provinceSelectController.addListener(_updateLocation);
    _citySelectController.addListener(_updateLocation);
    _countySelectController.addListener(_updateLocation);

    _addressController.addListener(() async {
      final value = _addressController.text;
      await widget.provider.setFieldValue('AllLeave1_OutAddress', value);
      widget.provider.setTemplateValue('outAddress', value);
    });
  }

  Future<void> _updateLocation() async {
    final provinceCode = _provinceSelectController.value.firstOrNull; // 一定是两位数
    var cityCode = _citySelectController.value.firstOrNull;
    var countyCode = _countySelectController.value.firstOrNull;

    if (provinceCode != null) {
      _setCity(provinceCode);
      cityCode = cityCode ?? _cities.keys.first;
      final province = _provinces[provinceCode]!;
      await widget.provider
          .setSelectValue('province', '$provinceCode'.padRight(6, '0'));
      widget.provider.setTemplateValue('a1', province);

      _setCounty(provinceCode, cityCode);
      countyCode = countyCode ?? _counties.keys.first;
      final city = _cities[cityCode]!;
      await widget.provider.setSelectValue(
          'city', '$provinceCode${cityCode.padL2}'.padRight(6, '0'));
      widget.provider.setTemplateValue('a2', city);

      final county = _counties[countyCode];
      await widget.provider.setSelectValue(
          'county', '$provinceCode${cityCode.padL2}${countyCode.padL2}');
      widget.provider.setTemplateValue('a3', county);

      widget.provider.setTemplateValue(
          'area', '$provinceCode${cityCode.padL2}${countyCode.padL2}');
      widget.provider.setTemplateValue('comeWhere1', '$province$city$county');
    }
  }

  @override
  void dispose() {
    _provinceSelectController.dispose();
    _citySelectController.dispose();
    _countySelectController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  void _loadProvinces() {
    _provinces.clear();
    for (final provinceCode in areaData.keys) {
      final name = areaData[provinceCode]!['_']! as String;
      _provinces[provinceCode] = name;
    }
    _refresh();
  }

  void _setCity(int provinceCode) {
    _cities.clear();
    final cities = areaData[provinceCode]!;
    for (final cityCode in cities.keys) {
      if (cityCode is! int) continue;
      final name = (cities[cityCode]! as Map<Object, String>)['_']!;
      _cities[cityCode] = name;
    }
    _refresh();
  }

  void _setCounty(int provinceCode, int cityCode) {
    _counties.clear();
    final counties = areaData[provinceCode]![cityCode]! as Map<Object, String>;
    for (final countyCode in counties.keys) {
      if (countyCode is! int) continue;
      final name = counties[countyCode]!;
      _counties[countyCode] = name;
    }
    _refresh();
  }

  void _loadArea(DailyLeaveOptions options) {
    final area = options.area;
    final provinceCode = int.parse(area.substring(0, 2));
    final cityCode = int.parse(area.substring(2, 4));
    final countyCode = int.parse(area.substring(4, 6));
    _provinceSelectController.update(provinceCode, selected: true);

    _setCity(provinceCode);
    _citySelectController.update(cityCode, selected: true);

    _setCounty(provinceCode, cityCode);
    _countySelectController.update(countyCode, selected: true);
  }

  Widget _buildLocationSelect(FSelectGroupController<int> controller,
      Map<int, String> data, String hint) {
    return FSelectMenuTile<int>.builder(
      groupController: controller,
      title: const Empty(),
      count: data.length,
      initialValue: {},
      menuTileBuilder: (context, index) {
        final code = data.keys.toList()[index];
        final name = data[code]!;
        return FSelectTile(title: Text(name), value: code);
      },
      details: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final code = controller.value.firstOrNull;
            final name = data[code];
            return Center(
              child: Text(
                name ?? hint,
                style: TextStyle(
                  color:
                      name == null ? null : context.theme.colorScheme.primary,
                ),
              ),
            );
          }),
      autoHide: true,
      maxHeight: 200,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) => controller.value.isEmpty ? '请选择一个正确的地址' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: joinGap(
        gap: 10,
        axis: Axis.vertical,
        widgets: [
          Text('地点', style: widget.provider.ts),
          Row(
            children: joinGap(gap: 8, axis: Axis.horizontal, widgets: [
              Expanded(
                  child: _buildLocationSelect(
                      _provinceSelectController, _provinces, '省')),
              Expanded(
                  child: _buildLocationSelect(
                      _citySelectController, _cities, '市')),
              Expanded(
                  child: _buildLocationSelect(
                      _countySelectController, _counties, '区'))
            ]),
          ),
          FTextField(
            controller: _addressController,
            maxLines: 1,
            label: Text('详细地址（必填）', style: widget.provider.ts2),
            // hint: '详细地址（必填）',
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
