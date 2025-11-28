import 'package:flutter/material.dart';
import 'package:swustmeow/components/account_card.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/color_mode.dart';
import 'package:swustmeow/services/boxes/common_box.dart';
import 'package:swustmeow/services/global_service.dart';

class SettingsAccountManagementPage extends StatefulWidget {
  const SettingsAccountManagementPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsAccountManagementPageState();
}

class _SettingsAccountManagementPageState
    extends State<SettingsAccountManagementPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Color? color;
    final colorMode = CommonBox.get('toolAccountColorMode') as ColorMode? ??
        ColorMode.colorful;
    final themeColor = CommonBox.get('themeColor') as int? ?? 0xFF1B7ADE;
    if (colorMode == ColorMode.theme) {
      color = Color(themeColor);
    }

    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '账号管理'),
      content: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MTheme.radius),
          child: Column(
            children: [
              for (int i = 0; i < GlobalService.services.length; i++) ...[
                if (i > 0) SizedBox(height: 16.0),
                AccountCard(
                  service: GlobalService.services[i],
                  color: color ?? GlobalService.services[i].color,
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
