import 'dart:ui';
import 'package:flutter/material.dart';

import '../../data/m_theme.dart';

class BasePage extends StatelessWidget {
  final Widget header;
  final Widget content;
  final Color? color;
  final bool roundedBorder;
  final bool headerPad;
  final double extraHeight;
  final DecorationImage? backgroundImage;
  final bool blurBackground;
  final double blurSigma;

  const BasePage({
    super.key,
    required this.header,
    required this.content,
    this.color,
    this.roundedBorder = true,
    this.headerPad = true,
    this.extraHeight = 0.0,
    this.backgroundImage,
    this.blurBackground = false,
    this.blurSigma = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: backgroundImage != null && !blurBackground
          ? BoxDecoration(
              color: Colors.white,
              image: backgroundImage,
            )
          : BoxDecoration(
              color: Colors.white,
            ),
      child: Stack(
        children: [
          if (backgroundImage == null)
            Container(
              decoration: BoxDecoration(color: color ?? MTheme.primary2),
            ),
          if (backgroundImage != null && blurBackground)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    image: backgroundImage,
                  ),
                ),
              ),
            ),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: headerPad
                      ? EdgeInsets.symmetric(horizontal: 16.0)
                      : EdgeInsets.zero,
                  child: header,
                ),
              ),
              Expanded(
                child: Opacity(
                  opacity: 1.0,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: backgroundImage == null
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: roundedBorder
                          ? BorderRadius.only(
                              topLeft: Radius.circular(MTheme.radius),
                              topRight: Radius.circular(MTheme.radius),
                            )
                          : null,
                    ),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
