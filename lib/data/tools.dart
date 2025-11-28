/*
 * Copyright (c) 2025 BEND
 *
 * This file is a secondary development based on the original project.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/services/app_launcher_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/views/chaoxing/chaoxing_exam_page.dart';
import 'package:swustmeow/views/chaoxing/chaoxing_homework_page.dart';

import '../entity/tool.dart';
import '../services/color_service.dart';
import '../services/global_service.dart';
import '../views/apartment/apartment_page.dart';
import '../views/duifene/duifene_homework_page.dart';
import '../views/duifene/duifene_signin_page.dart';
import '../views/soa/soa_evaluation_page.dart';
import '../views/soa/soa_exams_page.dart';
import '../views/soa/soa_leaves_page.dart';
import '../views/soa/soa_map_page.dart';
import '../views/soa/soa_scores_page.dart';
import '../views/ykt/ykt_page.dart';

class Tools {
  static List<Tool> defaultTools = [
    Tool(
      id: 'exams',
      name: '考试查询',
      path: '/exams',
      icon: Icon(FontAwesomeIcons.penNib),
      color: ColorService.soaColor,
      pageBuilder: () => SOAExamsPage(),
      serviceGetter: () => GlobalService.soaService,
      isVisible: true,
      order: 0,
    ),
    Tool(
      id: 'scores',
      name: '成绩查询',
      path: '/scores',
      icon: Icon(FontAwesomeIcons.solidStar),
      color: ColorService.soaColor,
      pageBuilder: () => SOAScoresPage(),
      serviceGetter: () => GlobalService.soaService,
      isVisible: true,
      order: 1,
    ),
    Tool(
      id: 'campusMap',
      name: '校园地图',
      path: '/campus_map',
      icon: Icon(FontAwesomeIcons.mapLocationDot),
      color: ColorService.soaColor,
      pageBuilder: () => SOAMapPage(),
      serviceGetter: () => null,
      isVisible: false,
      order: 2,
    ),
    Tool(
      id: 'leave',
      name: '请假',
      path: '/exams',
      icon: Icon(FontAwesomeIcons.solidCalendarPlus),
      color: ColorService.soaColor,
      pageBuilder: () => SOALeavesPage(),
      serviceGetter: () => GlobalService.soaService,
      isVisible: false,
      order: 3,
    ),
    Tool(
      id: 'evaluation',
      name: '教评提交',
      path: '/evaluation',
      icon: Icon(FontAwesomeIcons.clipboardCheck),
      color: ColorService.soaColor,
      pageBuilder: () => SOAEvaluationPage(),
      serviceGetter: () => GlobalService.soaService,
      isVisible: true,
      order: 4,
    ),
    Tool(
      id: 'ykt',
      name: '一卡通',
      path: '/ykt',
      icon: Icon(FontAwesomeIcons.solidCreditCard),
      color: ColorService.yktColor,
      pageBuilder: () => YKTPage(),
      serviceGetter: () => GlobalService.yktService,
      isVisible: false,
      order: 5,
    ),
    Tool(
      id: 'atrust',
      name: 'aTrust',
      path: '/atrust',
      icon: SvgPicture.asset('assets/icon/atrust.svg', width: 24, height: 24),
      color: ColorService.moreColor,
      pageBuilder: () => Scaffold(
        appBar: AppBar(title: const Text('aTrust')),
        body: const Center(child: Text('请使用工具直接启动')),
      ),
      serviceGetter: () => null,
      onTap: (context) async {
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
      isVisible: true,
      order: 6,
    ),
    Tool(
      id: 'apartment',
      name: '宿舍事务',
      path: '/apartment',
      icon: Icon(FontAwesomeIcons.solidBuilding),
      color: ColorService.apartmentColor,
      pageBuilder: () => ApartmentPage(),
      serviceGetter: () => GlobalService.apartmentService,
      isVisible: false,
      order: 7,
    ),
    Tool(
      id: 'duifeneHomework',
      name: '对分易作业',
      path: '/duifene/homework',
      icon: Icon(FontAwesomeIcons.solidFile),
      color: ColorService.duifeneColor,
      pageBuilder: () => DuiFenEHomeworkPage(),
      serviceGetter: () => GlobalService.duifeneService,
      isVisible: false,
      order: 8,
    ),
    Tool(
      id: 'duifeneSignIn',
      name: '对分易签到',
      path: '/duifene/sign_in',
      icon: Icon(FontAwesomeIcons.locationDot),
      color: ColorService.duifeneColor,
      pageBuilder: () => DuiFenESignInPage(),
      serviceGetter: () => GlobalService.duifeneService,
      isVisible: false,
      order: 9,
    ),
    Tool(
      id: 'chaoxingHomework',
      name: '学习通作业',
      path: '/chaoxing/homework',
      icon: Icon(FontAwesomeIcons.solidFile),
      color: ColorService.chaoxingColor,
      pageBuilder: () => ChaoXingHomeworkPage(),
      serviceGetter: () => GlobalService.chaoXingService,
      isVisible: false,
      order: 10,
    ),
    Tool(
      id: 'chaoxingExams',
      name: '学习通考试',
      path: '/chaoxing/exams',
      icon: Icon(FontAwesomeIcons.solidStar),
      color: ColorService.chaoxingColor,
      pageBuilder: () => ChaoXingExamsPage(),
      serviceGetter: () => GlobalService.chaoXingService,
      isVisible: false,
      order: 11,
    ),
  ];

  static ValueNotifier<List<Tool>> tools =
      ValueNotifier<List<Tool>>([...defaultTools]);
}
