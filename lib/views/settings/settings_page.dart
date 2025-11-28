import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/data/m_theme.dart';

import '../../components/settings/settings_about.dart';
import '../../components/settings/settings_appearance.dart';
import '../../components/settings/settings_common.dart';
import '../../components/settings/settings_account.dart';
import '../../utils/widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.onRefresh,
  });

  final Function() onRefresh;

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(MTheme.radius);

    return BasePage(
      headerPad: false,
      header: BaseHeader(
        showBackButton: false,
        title: '设置',
      ),
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
              const SettingsAccount(),
              SettingsAppearance(onRefresh: widget.onRefresh),
              SettingsCommon(onRefresh: widget.onRefresh),
              const SettingsAbout(),
            ],
          ),
        ),
      ),
    );
  }
}
