import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/simple_setting_item.dart';
import 'package:swustmeow/components/simple_settings_group.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';

import '../../data/m_theme.dart';
import '../../entity/run_mode.dart';
import '../../services/boxes/common_box.dart';
import '../../utils/widget.dart';

class SettingsBackgroundService extends StatefulWidget {
  const SettingsBackgroundService({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsBackgroundServiceState();
}

class _SettingsBackgroundServiceState extends State<SettingsBackgroundService> {
  RunMode _runMode = RunMode.foreground;
  bool _enableNotification = true;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  Future<void> _loadStates() async {
    final runMode =
        (CommonBox.get('bgServiceRunMode') as RunMode?) ?? RunMode.foreground;
    _enableNotification =
        (CommonBox.get('bgServiceNotification') as bool?) ?? true;
    _runMode = runMode;
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(MTheme.radius);

    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '后台服务'),
      content: Container(
        decoration: BoxDecoration(
          color: context.theme.colorScheme.secondary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
          ),
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 48.0),
          children: joinGap(
            gap: 8,
            axis: Axis.vertical,
            widgets: [
              SimpleSettingsGroup(
                title: '后台服务',
                children: [
                  SimpleSettingItem.dropdown<RunMode>(
                    title: '运行模式',
                    subtitle:
                        '前台运行：只能保持应用在前台活跃状态，退出后可以继续运行直到应用后台被杀死，此模式下即使下方「显示通知」的选项被关闭，依旧会在最开始启动时发送一条通知\n\n后台运行：应用关闭或彻底退出（后台被杀死）仍然运行，更耗电，需要对本应用关闭电池优化',
                    icon: FontAwesomeIcons.gear,
                    value: _runMode,
                    items: [
                      SimpleDropdownItem(
                        label: '前台运行',
                        value: RunMode.foreground,
                      ),
                      SimpleDropdownItem(
                        label: '后台运行',
                        value: RunMode.background,
                      ),
                    ],
                    onChanged: (value) async {
                      await CommonBox.put('bgServiceRunMode', value);
                    },
                  ),
                  SimpleSettingItem(
                    title: '显示通知',
                    subtitle: '开启一个无法关闭的通知，在运行时有助于随时查看状态，需要开启通知权限',
                    icon: FontAwesomeIcons.bell,
                    suffix: FSwitch(
                      value: _enableNotification,
                      onChange: (value) async {
                        final service = FlutterBackgroundService();
                        service.invoke(
                            'changeNotificationStatus', {'value': value});
                        await CommonBox.put('bgServiceNotification', value);
                        _refresh(() => _enableNotification = value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
