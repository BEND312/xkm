import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/simple_setting_item.dart';
import 'package:swustmeow/components/simple_settings_group.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/services/boxes/common_box.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/views/settings/settings_background_service.dart';

import '../../utils/common.dart';

class SettingsCommon extends StatefulWidget {
  final Function() onRefresh;

  const SettingsCommon({super.key, required this.onRefresh});

  @override
  State<SettingsCommon> createState() => _SettingsCommonState();
}

class _SettingsCommonState extends State<SettingsCommon> {
  bool _smsAutoFillEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _smsAutoFillEnabled = CommonBox.get('smsAutoFillEnabled') as bool? ?? false;
    });
  }

  Future<void> _saveSmsAutoFillSetting(bool value) async {
    await CommonBox.put('smsAutoFillEnabled', value);
    setState(() {
      _smsAutoFillEnabled = value;
    });
    showSuccessToast(value ? '已开启短信自动填充' : '已关闭短信自动填充');
  }

  @override
  Widget build(BuildContext context) {
    return SimpleSettingsGroup(
      title: '通用',
      children: [
        SimpleSettingItem(
          title: '短信自动填充登录',
          subtitle: _smsAutoFillEnabled ? '开启后账号管理登录时自动读取验证码' : '关闭后需手动输入验证码',
          icon: FontAwesomeIcons.message,
          hasSuffix: true,
          suffix: FSwitch(
            value: _smsAutoFillEnabled,
            onChange: _saveSmsAutoFillSetting,
          ),
        ),
        SimpleSettingItem(
          title: '清理缓存',
          subtitle: '可用于刷新课表、校历等',
          icon: FontAwesomeIcons.trash,
          hasSuffix: false,
          onPress: () {
            clearCaches();
            widget.onRefresh();
            showSuccessToast('清理完成');
          },
        ),
        SimpleSettingItem(
          title: '清理 Cookie 缓存',
          subtitle: '可用于官方网站登录缓存',
          icon: FontAwesomeIcons.trash,
          hasSuffix: false,
          onPress: () async {
            final result = await GlobalService.webViewCookieManager?.deleteAllCookies();
            if (result == true) {
              showSuccessToast('清理完成');
            } else {
              showErrorToast('清理失败');
            }
          },
        ),
        SimpleSettingItem(
          title: '后台服务',
          subtitle: '后台服务的相关设置，用于一些持续性任务',
          icon: FontAwesomeIcons.gear,
          onPress: () => pushTo(context, '/settings/background_service',
              const SettingsBackgroundService()),
        ),
      ],
    );
  }
}
