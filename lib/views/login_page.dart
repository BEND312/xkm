/*
 * Copyright (c) 2025 BEND
 *
 * This file is a secondary development based on the original project.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:swustmeow/entity/button_state.dart';
import 'package:swustmeow/components/login_pages/login_page_base.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/utils/widget.dart';
import 'package:swustmeow/views/main_page.dart';
import 'package:swustmeow/services/app_launcher_service.dart';
import 'package:swustmeow/utils/common.dart';

import '../components/utils/back_again_blocker.dart';
import '../data/values.dart';
import '../services/global_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.loadPage});

  final LoginPageBase Function({
    required ButtonStateContainer sc,
    required Function(ButtonStateContainer sc) onStateChange,
    required Function({bool toEnd}) onComplete,
    required bool onlyThis,
  })? loadPage;

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  ButtonStateContainer _sc =
      const ButtonStateContainer(ButtonState.dissatisfied);
  int _currentPage = 0;
  late PageController _pageController;
  List<Widget> _pageList = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _waitForServicesAndInitialize();
  }
  
  Future<void> _waitForServicesAndInitialize() async {
    while (GlobalService.services.isEmpty && widget.loadPage == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    if (mounted) {
      _initializePages();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _initializePages() {
    _pageList = [const SizedBox.shrink()];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _refresh([Function()? fn]) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> buildPageList() {
      onStateChange(ButtonStateContainer sc) => _refresh(() => _sc = sc);
      onComplete({bool toEnd = false}) {
        final count = widget.loadPage == null ? GlobalService.services.length : 1;
        if (_currentPage >= count - 1 || toEnd) {
          pushReplacement(
            context,
            '/',
            const BackAgainBlocker(child: MainPage()),
            force: true,
          );
          return;
        }

        _refresh(() {
          _currentPage++;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        });
      }

      if (widget.loadPage != null) {
        return [
          widget.loadPage!(
            sc: _sc,
            onStateChange: onStateChange,
            onComplete: onComplete,
            onlyThis: true,
          )
        ];
      }

      return GlobalService.services
          .map(
            (service) => service.getLoginPage(
              sc: _sc,
              onStateChange: onStateChange,
              onComplete: onComplete,
              onlyThis: false,
            ),
          )
          .toList();
    }

    if (_isInitialized) {
      _pageList = buildPageList();
    }
    
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: ClipRRect(
              child: Container(
                width: 400,
                height: 450,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fitWidth,
                    image: AssetImage('assets/images/gradient_circle.jpg'),
                    colorFilter:
                        ColorFilter.mode(MTheme.primary2, BlendMode.hue),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_isInitialized) {
      return Padding(
        padding: EdgeInsets.all(MTheme.radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(MTheme.radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: joinGap(
          gap: 12,
          axis: Axis.vertical,
          widgets: [
            _buildHeader(),
            Flexible(
              child: ExpandablePageView.builder(
                itemCount: _pageList.length,
                itemBuilder: (context, index) {
                  final page = _pageList[index];
                  return page;
                },
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: MTheme.primary1,
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            '欢迎来到${Values.name}',
            style: TextStyle(
              fontSize: 20,
              color: MTheme.primary1,
            ),
          ),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              const packageName = 'com.sangfor.atrust';
              final isInstalled = await AppLauncherService.isAppInstalled(packageName);
              
              if (!isInstalled) {
                showErrorToast('未安装深信服 aTrust 应用');
                final shouldOpen = await showDialog<bool>(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('提示'),
                    content: const Text('未检测到深信服 aTrust 应用，是否前往应用商店下载？'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('前往'),
                      ),
                    ],
                  ),
                );
                
                if (shouldOpen == true) {
                  final success = await AppLauncherService.openAppInStore(packageName);
                  if (!success) {
                    showErrorToast('打开应用商店失败');
                  }
                }
                return;
              }
              final success = await AppLauncherService.launchAppByPackageName(packageName);
              
              if (!success) {
                showErrorToast('启动失败，请手动打开应用');
              }
            },
            icon: SvgPicture.asset('assets/icon/atrust.svg', width: 20, height: 20),
            label: Text('一键打开ATrust'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MTheme.primary1,
              side: BorderSide(color: MTheme.primary1.withOpacity(0.5)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
