/*
 * Copyright (c) 2025 BEND
 *
 * This file is a secondary development based on the original project.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/components/utils/pop_receiver.dart';
import 'package:swustmeow/data/tools.dart';
import 'package:swustmeow/services/color_service.dart';
import 'package:swustmeow/services/tool_service.dart';
import 'package:swustmeow/utils/router.dart';

import '../../entity/tool.dart';
import '../../utils/common.dart';
import '../../views/tools_page.dart';

class HomeToolGrid extends StatefulWidget {
  const HomeToolGrid({super.key, required this.padding});

  final double padding;

  @override
  State<StatefulWidget> createState() => _HomeToolGridState();
}

class _HomeToolGridState extends State<HomeToolGrid> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const columns = 5;

    return ValueListenableBuilder<List<Tool>>(
      valueListenable: Tools.tools,
      builder: (context, allTools, _) {
        // 筛选出要显示的工具（只显示用户设为可见的工具）
        final displayTools = allTools
            .where((tool) => tool.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        // 添加"更多"工具
        final allToolsWithMore = [
          ...displayTools,
          Tool(
            id: 'more',
            name: '更多',
            icon: Icon(FontAwesomeIcons.ellipsis),
            color: ColorService.moreColor,
            pageBuilder: () => PopReceiver(
              onPop: () => setState(() {}),
              child: ToolsPage(padding: widget.padding),
            ),
            isVisible: true,
            order: 999,
            path: '/tools/more',
          ),
        ];

        final size = MediaQuery.of(context).size.width;
        final dimension = (size - (widget.padding * 2)) / columns;
        final rows = (allToolsWithMore.length / columns).ceil();

        return SizedBox(
          height: dimension * rows,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 1,
            ),
            itemCount: allToolsWithMore.length,
            itemBuilder: (context, index) {
              final tool = allToolsWithMore[index];
              final service =
                  tool.serviceGetter == null ? null : tool.serviceGetter!();
              final isLoginNotifier = service == null
                  ? ValueNotifier(true)
                  : service.isLoginNotifier;

              return ValueListenableBuilder(
                valueListenable: isLoginNotifier,
                builder: (context, isLogin, _) {
                  return GestureDetector(
                    onTap: () async {
                      if (!isLogin) {
                        showErrorToast(
                            '未登录${service != null ? service.name : ''}');
                        return;
                      }
                      ToolService.recordToolUsage(tool.id);
                      
                      if (tool.onTap != null) {
                        await tool.onTap!(context);
                      } else {
                        pushTo(context, tool.path, tool.pageBuilder(),
                            pushInto: true);
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.all(4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: tool.color,
                            builder: (context, color, _) => SizedBox(
                              width: 24,
                              height: 24,
                              child: tool.icon is SvgPicture
                                  ? tool.icon
                                  : ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        isLogin
                                            ? color
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
                            maxFontSize: 11,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            physics: const NeverScrollableScrollPhysics(),
          ),
        );
      },
    );
  }
}
