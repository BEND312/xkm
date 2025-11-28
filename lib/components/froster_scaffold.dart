import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// 修改自 [FScaffold]
class FrostedScaffold extends StatelessWidget {
  const FrostedScaffold({
    super.key,
    required this.content,
    this.header,
    this.footer,
    this.contentPad = true,
    this.style,
    this.footerOpacity = 1.0,
  });

  final Widget content;
  final Widget? header;
  final Widget? footer;
  final bool contentPad;
  final FScaffoldStyle? style;
  final double footerOpacity;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? context.theme.scaffoldStyle;
    Widget content = this.content;

    if (contentPad) {
      content = Padding(padding: style.contentPadding, child: content);
    }

    return ColoredBox(
      color: style.backgroundColor,
      child: Column(
        children: [
          if (header != null)
            DecoratedBox(decoration: style.headerDecoration, child: header!),
          Expanded(
            child: Stack(
              children: [
                content,
                if (footer != null)
                  Opacity(
                    opacity: footerOpacity,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: DecoratedBox(
                        decoration: style.footerDecoration,
                        child: ClipRect(
                          child: RepaintBoundary(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 8.0,
                                sigmaY: 8.0,
                                tileMode: TileMode.decal,
                              ),
                              child: Opacity(
                                opacity: 0.75,
                                child: footer!,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
