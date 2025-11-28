/*
 * Copyright (c) 2025 BEND
 *
 * This file is a secondary development based on the original project.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/data/tools.dart';
import 'package:swustmeow/entity/tool.dart';
import 'package:swustmeow/services/tool_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/views/simple_webview_page.dart';
import 'package:swustmeow/views/soa/new_soa_portal_page.dart';
import 'package:vibration/vibration.dart';
import '../utils/router.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key, required this.padding});

  final double padding;

  @override
  State<StatefulWidget> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  bool _isEditMode = false;
  List<Tool> _tools = [];
  List<String> _visibleToolIds = [];

  @override
  void initState() {
    super.initState();
    _tools = Tools.tools.value;
    _visibleToolIds =
        _tools.where((tool) => tool.isVisible).map((tool) => tool.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(
        title: '工具',
        suffixIcons: [
          if (_isEditMode)
            IconButton(
              icon: FaIcon(
                FontAwesomeIcons.rotateRight,
                color: MTheme.backgroundText,
              ),
              onPressed: () async {
                await ToolService.resetToDefault();
                setState(() {
                  _tools = Tools.tools.value;
                  _visibleToolIds = _tools
                      .where((tool) => tool.isVisible)
                      .map((tool) => tool.id)
                      .toList();
                });
                showSuccessToast('工具布局已重置');
              },
            ),
          IconButton(
            icon: FaIcon(
              _isEditMode ? FontAwesomeIcons.check : FontAwesomeIcons.pen,
              color: MTheme.backgroundText,
            ),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
          ),
        ],
      ),
      content: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildGrid(),
          SizedBox(height: 24),
          _buildWebsites(),
          SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final tools = Tools.tools.value.where((tool) => true).toList();
    int columns = tools.length <= 6 ? 3 : 4;

    return Padding(
      padding: EdgeInsets.all(8),
      child: ReorderableGrid(
        shrinkWrap: true,
        padding: EdgeInsets.only(top: 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          final service =
              tool.serviceGetter != null ? tool.serviceGetter!() : null;
          final isLogin = service == null ? true : service.isLogin;
          final isVisible = _visibleToolIds.contains(tool.id);

          return Container(
            key: Key(tool.id),
            decoration: BoxDecoration(
              // color: Colors.white,
              borderRadius: BorderRadius.circular(MTheme.radius),
            ),
            child: ReorderableGridDelayedDragStartListener(
              index: index,
              child: Stack(
                children: [
                  Center(
                    child: FTappable(
                      onPress: () => _onToolPressed(tool),
                      child: SizedBox(
                        height: double.infinity,
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ValueListenableBuilder(
                              valueListenable: tool.color,
                              builder: (context, color, _) => SizedBox(
                                width: 26,
                                height: 26,
                                child: tool.icon is SvgPicture
                                    ? tool.icon
                                    : ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          isLogin
                                              ? color.withValues(alpha: 1)
                                              : Colors.grey.withValues(alpha: 0.4),
                                          BlendMode.srcIn,
                                        ),
                                        child: tool.icon,
                                      ),
                              ),
                            ),
                            SizedBox(height: 4.0),
                            AutoSizeText(
                              tool.name,
                              minFontSize: 6,
                              maxFontSize: 12,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isEditMode)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _toggleToolVisibility(tool.id),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isVisible
                                ? Colors.green.withValues(alpha: 0.9)
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                          child: isVisible
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        physics: const NeverScrollableScrollPhysics(),
        onReorder: (int oldIndex, int newIndex) async {
          final widget = _tools.removeAt(oldIndex);
          _tools.insert(newIndex, widget);
          await ToolService.updateToolOrder(_tools);
          setState(() {});
        },
        onReorderStart: (_) async {
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 100, sharpness: 0.2);
          }
        },
        proxyDecorator: (child, index, animation) => AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue =
                Curves.easeInOut.transform(animation.value);
            final double elevation = lerpDouble(0, 6, animValue)!;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(MTheme.radius),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: 0.12 + elevation * 0.04),
                    blurRadius: 3.0 + elevation * 1.5,
                    spreadRadius: -1.0 + elevation * 0.5,
                    offset: Offset(0, 1.0 + elevation * 0.5),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: child,
        ),
      ),
    );
  }

  Future<void> _toggleToolVisibility(String toolId) async {
    final isVisible = _visibleToolIds.contains(toolId);

    setState(() {
      if (isVisible) {
        _visibleToolIds.remove(toolId);
        ToolService.updateToolVisibility(toolId, false);
      } else {
        _visibleToolIds.add(toolId);
        ToolService.updateToolVisibility(toolId, true);
      }
    });
  }

  void _onToolPressed(Tool tool) async {
    final service = tool.serviceGetter != null ? tool.serviceGetter!() : null;
    final isLogin = service == null ? true : service.isLogin;

    if (_isEditMode) {
      _toggleToolVisibility(tool.id);
      return;
    }

    if (!isLogin) {
      showErrorToast('未登录${service.name}');
      return;
    }

    if (!mounted) return;

    if (tool.onTap != null) {
      await tool.onTap!(context);
    } else {
      pushTo(context, tool.path, tool.pageBuilder(), pushInto: true);
    }

    await ToolService.recordToolUsage(tool.id);
    setState(() {});
  }

  Widget _buildWebsites() {
    final columns = 4;
    final websites = [
      _buildWebsiteItem(
        FontAwesomeIcons.school,
        '学校主页',
        'https://www.swust.edu.cn/',
        Colors.red,
      ),
      _buildWebsiteItem(
        FontAwesomeIcons.buildingColumns,
        'OA系统',
        'https://soa.swust.edu.cn/sys/portal/page.jsp',
        Colors.blue,
      ),
      _buildWebsiteItem(
        FontAwesomeIcons.house,
        '一站式大厅',
        '/new_soa_portal',
        Colors.blue,
        isInternalPage: true,
      ),
      _buildWebsiteItem(
        FontAwesomeIcons.userGraduate,
        '数智学工',
        'https://yzs.swust.edu.cn/xg/app',
        Colors.teal,
      ),
      _buildWebsiteItem(
        FontAwesomeIcons.calendarDay,
        '教务系统',
        'https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=studentPortal:DEFAULT_EVENT',
        Colors.orange,
      ),
      _buildWebsiteItem(
        FontAwesomeIcons.flask,
        '实践教学',
        'https://sjjx.dean.swust.edu.cn/swust',
        Colors.indigo,
      ),
      _buildWebsiteItem(
        FontAwesomeIcons.bookOpen,
        '图书馆',
        'https://lib.swust.edu.cn/',
        Colors.green,
      ),
      _buildWebsiteItem(
        FontAwesomeIcons.bed,
        '公寓中心',
        'http://gydb.swust.edu.cn/sgH5/',
        Colors.brown,
      ),
      _buildWebsiteItem(
        FontAwesomeIcons.solidCreditCard,
        '一卡通',
        'http://ykt.swust.edu.cn/plat/shouyeUser',
        Colors.teal,
      ),
      _buildWebsiteItem(
        FontAwesomeIcons.moneyBillWave,
        '财务系统',
        'https://pay.swust.edu.cn/paygateway/sso.jsp',
        Colors.purple,
      ),
      _buildWebsiteItem(
        FontAwesomeIcons.print,
        '自助打印',
        'https://npm.swust.edu.cn/api/auth/caslogin?deviceName=207',
        Colors.blue,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '官方网站',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 1,
            ),
            itemCount: websites.length,
            itemBuilder: (context, index) => websites[index],
            physics: const NeverScrollableScrollPhysics(),
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteItem(
    IconData icon,
    String name,
    String url,
    Color color, {
    bool isInternalPage = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: FTappable(
        onPress: () {
          if (isInternalPage) {
            if (url == '/new_soa_portal') {
              pushTo(context, '/new_soa_portal', const NewSOAPortalPage(), pushInto: true);
              return;
            }
            final tool = Tools.tools.value.firstWhere(
              (t) => t.path == url,
              orElse: () => Tools.tools.value.first,
            );
            pushTo(context, tool.path, tool.pageBuilder(), pushInto: true);
          } else {
            pushTo(
              context,
              '/websites/$name-$url',
              SimpleWebViewPage(initialUrl: url),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              color: color.withValues(alpha: 0.8),
              size: 24,
            ),
            SizedBox(height: 4.0),
            AutoSizeText(
              name,
              minFontSize: 6,
              maxFontSize: 12,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
