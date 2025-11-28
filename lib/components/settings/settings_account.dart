import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/views/settings/settings_account_management_page.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/views/login_page.dart';

import '../../data/values.dart';
import '../simple_setting_item.dart';
import '../simple_settings_group.dart';
import '../utils/back_again_blocker.dart';

class SettingsAccount extends StatelessWidget {
  const SettingsAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleSettingsGroup(
      title: '账号',
      children: [
        SimpleSettingItem(
          title: '账号管理',
          subtitle: '管理你的一站式服务、对分易等账号',
          icon: FontAwesomeIcons.usersGear,
          onPress: () => pushTo(context, '/settings/account_management',
              const SettingsAccountManagementPage()),
        ),
        SimpleSettingItem(
          title: '退出登录',
          subtitle: '退出所有账号',
          icon: FontAwesomeIcons.rightFromBracket,
          hasSuffix: false,
          color: Colors.red,
          onPress: () => _showLogoutDialog(context),
        ),
        SimpleSettingItem(
          title: '注销账号',
          icon: FontAwesomeIcons.userXmark,
          hasSuffix: false,
          color: Colors.red,
          onPress: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  void _showLogoutDialog(final BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => FDialog(
        direction: Axis.horizontal,
        title: const Text('确定要这样做吗？'),
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: const Text('之后，你会返回到初始页面，并且需要重新登录所有的账号，所有的缓存都会被清空'),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            label: Text(
              '算了吧',
              style: Values.dialogButtonTextStyle,
            ),
          ),
          FButton(
            onPress: () async => _logoutAll(context),
            label: Text('我确定', style: Values.dialogButtonTextStyle),
            style: FButtonStyle.outline,
          )
        ],
      ),
    );
  }

  Future<void> _logoutAll(BuildContext context) async {
    for (final service in GlobalService.services) {
      service.logout(notify: true);
    }

    if (context.mounted) {
      pushReplacement(
        context,
        '/login',
        const BackAgainBlocker(
          child: LoginPage(),
        ),
      );
    }
  }
}
