/*
 * Copyright (c) 2025 BEND
 *
 * This file is a new addition to the project, created as part of secondary development.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'package:flutter/material.dart';
import 'package:swustmeow/components/base_webview.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';

class NewSOAPortalPage extends StatefulWidget {
  const NewSOAPortalPage({super.key});

  @override
  State<StatefulWidget> createState() => _NewSOAPortalPageState();
}

class _NewSOAPortalPageState extends State<NewSOAPortalPage> {
  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: const BaseHeader(title: '一站式大厅'),
      content: const BaseWebView(
        url: 'http://cas.swust.edu.cn/authserver/login?service=https://mk.swust.edu.cn/web/?CASLOGIN=CASLOGIN',
      ),
    );
  }
}