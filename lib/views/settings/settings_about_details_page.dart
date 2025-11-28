import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';

import '../../data/m_theme.dart';
import '../../data/values.dart';
import '../../utils/router.dart';
import '../agreements/license_page.dart' as license_page;

class SettingsAboutDetailsPage extends StatefulWidget {
  const SettingsAboutDetailsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsAboutDetailsPageState();
}

class _SettingsAboutDetailsPageState extends State<SettingsAboutDetailsPage> {

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '关于'),
      content: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildAppHeader(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 70,
              height: 70,
              child: Image.asset('assets/icon/icon.png'),
            ),
          ),
          Text(
            Values.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MTheme.primary2.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'v${Values.version}-${Values.buildVersion}',
              style: TextStyle(
                color: MTheme.primary2.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final color = Colors.black54;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(
            '基于swustmeow-app二次开发',
            style: TextStyle(color: color, fontSize: 13),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final url = Uri.parse('https://github.com/swust-store/swustmeow-app');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              'GitHub页面',
              style: TextStyle(
                color: MTheme.primary2,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              pushTo(context, '/agreements/license', const license_page.LicensePage());
            },
            child: Text(
              '开放源代码许可',
              style: TextStyle(
                color: MTheme.primary2,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '版权所有 © 2025 s-meow.com',
            style: TextStyle(color: color, fontSize: 13),
          ),
          SizedBox(height: 4),
          // 移除用户协议和隐私政策链接
        ],
      ),
    );
  }
}
