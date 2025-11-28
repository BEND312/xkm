import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/components/simple_settings_group.dart';
import 'package:swustmeow/components/utils/pop_receiver.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/views/settings/settings_appearance_page.dart';
import 'package:swustmeow/views/settings/settings_theme_page.dart';

import '../simple_setting_item.dart';

class SettingsAppearance extends StatelessWidget {
  final Function() onRefresh;

  const SettingsAppearance({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return SimpleSettingsGroup(
      title: '外观',
      children: [
        SimpleSettingItem(
          title: '主题设置',
          subtitle: '全局配色、自定义背景与取色',
          icon: FontAwesomeIcons.palette,
          onPress: () => pushTo(
            context,
            '/setting/theme',
            PopReceiver(
              onPop: onRefresh,
              child: SettingsThemePage(onSelectColor: onRefresh),
            ),
          ),
        ),
        SimpleSettingItem(
          title: '外观设置',
          subtitle: '调整首页一言、工具栏等样式',
          icon: FontAwesomeIcons.highlighter,
          onPress: () => pushTo(
            context,
            '/setting/appearance',
            PopReceiver(
              onPop: onRefresh,
              child: SettingsAppearancePage(onSelectColor: onRefresh),
            ),
          ),
        ),
      ],
    );
  }
}
