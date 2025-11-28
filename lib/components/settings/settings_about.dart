import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/values.dart';
import '../../utils/router.dart';
import '../../views/settings/settings_about_details_page.dart';
import '../simple_setting_item.dart';
import '../simple_settings_group.dart';

class SettingsAbout extends StatefulWidget {
  const SettingsAbout({super.key});

  @override
  State<SettingsAbout> createState() => _SettingsAboutState();
}

class _SettingsAboutState extends State<SettingsAbout> {

  @override
  Widget build(BuildContext context) {
    final detailsStyle = TextStyle(fontSize: 14, color: Colors.black);

    return SimpleSettingsGroup(
      title: '关于',
      children: [
        SimpleSettingItem(
          title: '当前版本',
          icon: FontAwesomeIcons.tags,
          suffix: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'v${Values.version}-${Values.buildVersion}',
              style: detailsStyle,
            ),
          ),
        ),
        SimpleSettingItem(
          title: '关于',
          icon: FontAwesomeIcons.circleInfo,
          onPress: () => pushTo(
              context, '/settings/about', const SettingsAboutDetailsPage()),
        ),
      ],
    );
  }
}
