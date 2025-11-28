import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_randomcolor/flutter_randomcolor.dart';

import '../data/m_theme.dart';

int hexToInt(String hex) => int.parse('0xff${hex.substring(1)}');

Color hexToColor(String hex) => Color(hexToInt(hex));

int randomColor() =>
    RandomColor.getColorObject(Options(luminosity: Luminosity.light, alpha: 1))
        .toInt();

/// 哈希函数将字符串转为颜色
Color generateColorFromString(
  String string, {
  double minBrightness = 0.5,
  double saturationFactor = 1,
}) {
  // 对名称进行 MD5 哈希，确保唯一
  var bytes = utf8.encode(string);
  var hash = md5.convert(bytes).toString();

  // 将哈希字符串的部分转换成 RGB 分量
  int r = int.parse(hash.substring(0, 2), radix: 16);
  int g = int.parse(hash.substring(2, 4), radix: 16);
  int b = int.parse(hash.substring(4, 6), radix: 16);

  // 转换为 HSL 并限制最小亮度，确保不会太暗
  HSLColor hsl = HSLColor.fromColor(Color.fromARGB(255, r, g, b));
  double brightness = max(hsl.lightness, minBrightness);
  double adjustedSaturation = hsl.saturation * saturationFactor;

  return hsl
      .withLightness(brightness)
      .withSaturation(adjustedSaturation)
      .toColor();
}

int _floatToInt8(double x) {
  return (x * 255.0).round() & 0xff;
}

/// 根据基础颜色生成一系列从深到浅的颜色
/// [baseColor] 是基础颜色（相当于primary2）
/// 返回 [primary0, primary1, primary2, primary3, primary4, primary5] 的列表
List<Color> generatePrimaryColors(Color baseColor) {
  // 使用HSL颜色空间调整亮度
  HSLColor hslBase = HSLColor.fromColor(baseColor);

  // primary0比基础颜色更深（减少亮度，增加饱和度）
  Color primary0 = hslBase
      .withLightness((hslBase.lightness - 0.3).clamp(0.0, 1.0))
      .withSaturation((hslBase.saturation + 0.3).clamp(0.0, 1.0))
      .toColor();

  // primary1比基础颜色更深（减少亮度，增加饱和度）
  Color primary1 = hslBase
      .withLightness((hslBase.lightness - 0.1).clamp(0.0, 1.0))
      .withSaturation((hslBase.saturation + 0.1).clamp(0.0, 1.0))
      .toColor();

  // primary2就是基础颜色
  Color primary2 = baseColor;

  // primary3比基础颜色更浅（增加亮度，减少饱和度）
  Color primary3 = hslBase
      .withLightness((hslBase.lightness + 0.1).clamp(0.0, 1.0))
      // .withSaturation((hslBase.saturation - 0.1).clamp(0.0, 1.0))
      .toColor();

  // primary4更浅（更高亮度，更低饱和度）
  Color primary4 = hslBase
      .withLightness((hslBase.lightness + 0.2).clamp(0.0, 1.0))
      // .withSaturation((hslBase.saturation - 0.2).clamp(0.0, 1.0))
      .toColor();

  // primary5更浅
  Color primary5 = hslBase
      .withLightness((hslBase.lightness + 0.4).clamp(0.0, 1.0))
      .withSaturation((hslBase.saturation + 0.1).clamp(0.0, 1.0))
      .toColor();

  return [primary0, primary1, primary2, primary3, primary4, primary5];
}

extension ColorExtension on Color {
  int toInt() {
    return _floatToInt8(a) << 24 |
        _floatToInt8(r) << 16 |
        _floatToInt8(g) << 8 |
        _floatToInt8(b) << 0;
  }

  /// darkness: [[0, 1]]
  Color withDarkness(double darkness) {
    darkness = darkness > 1
        ? 1
        : darkness < 0
            ? 0
            : darkness;
    final d = (1 - darkness);
    return Color.fromARGB(
      (a * 255).toInt(),
      (r * 255 * d).toInt(),
      (g * 255 * d).toInt(),
      (b * 255 * d).toInt(),
    );
  }

  /// 调整饱和度，参数 [saturation] 范围为 0.0 ~ 1.0
  Color withSaturation(double saturation) {
    final hsv = HSVColor.fromColor(this);
    // 使用 HSVColor 内置的 withSaturation 方法
    final newHsv = hsv.withSaturation(saturation);
    return newHsv.toColor();
  }

  /// 调整亮度（即 HSV 中的 value），参数 [brightness] 范围为 0.0 ~ 1.0
  Color withBrightness(double brightness) {
    final hsv = HSVColor.fromColor(this);
    // 使用 HSVColor 内置的 withValue 方法
    final newHsv = hsv.withValue(brightness);
    return newHsv.toColor();
  }
}

/// 根据字符串从颜色调色板中获取确定性随机颜色
/// [string] 输入字符串，相同的字符串始终返回相同的颜色
/// [palette] 可选参数，指定颜色列表，默认使用MTheme.palette
/// 返回从调色板中选择的颜色
Color? getColorFromPaletteWithString(String string, {List<Color>? palette}) {
  // 如果未提供调色板，则使用MTheme.palette
  final colorPalette = palette ?? MTheme.courseTablePalette;

  if (colorPalette == null || colorPalette.isEmpty) {
    return null;
  }

  // 计算字符串的哈希值
  var hash = 0;
  for (var i = 0; i < string.length; i++) {
    hash = string.codeUnitAt(i) + ((hash << 5) - hash);
  }

  // 确保哈希值为正数
  hash = hash.abs();

  // 使用哈希值获取颜色索引
  final index = hash % colorPalette.length;

  // 返回对应的颜色
  return colorPalette[index];
}

/// 根据字符串从颜色调色板中获取确定性随机颜色（带亮度调整）
/// [string] 输入字符串
/// [palette] 可选参数，指定颜色列表，默认使用MTheme.palette
/// [minBrightness] 最小亮度，确保颜色不会太暗
/// [maxBrightness] 最大亮度，确保颜色不会太亮
/// 返回从调色板中选择的颜色（经过亮度调整）
Color? getColorFromPaletteWithStringAndBrightness(
  String string, {
  List<Color>? palette,
  double minBrightness = 0.2,
  double maxBrightness = 0.5,
}) {
  // 获取原始颜色
  final color = getColorFromPaletteWithString(string, palette: palette);
  if (color == null) return null;

  // 转换为HSL并调整亮度
  final hsl = HSLColor.fromColor(color);

  // 确保亮度
  if (hsl.lightness < minBrightness || hsl.lightness > maxBrightness) {
    return hsl
        .withLightness(hsl.lightness.clamp(minBrightness, maxBrightness))
        .toColor();
  }

  return color;
}

/// 根据给定颜色生成深色和浅色变体
/// [baseColor] 基础颜色
/// [darkBlend] 深色混合系数，值越大，越接近纯黑色，范围[0,1]
/// [lightBlend] 浅色混合系数，值越大，越接近纯白色，范围[0,1]
/// 返回一个包含深色和浅色变体的记录(darkVariant, lightVariant)
({Color darkVariant, Color lightVariant}) generateColorVariants(
  Color baseColor, {
  double darkBlend = 0.6,
  double lightBlend = 0.9,
}) {
  // 确保混合系数在有效范围内
  darkBlend = darkBlend.clamp(0.0, 1.0);
  lightBlend = lightBlend.clamp(0.0, 1.0);

  // 转换为HSL颜色空间，便于调整亮度
  HSLColor hslColor = HSLColor.fromColor(baseColor);

  // 创建深色变体
  // 降低亮度，同时保持一些原始颜色的色相和饱和度
  Color darkVariant = HSLColor.fromAHSL(
    hslColor.alpha,
    hslColor.hue,
    hslColor.saturation * (1 - darkBlend * 0.5), // 略微降低饱和度
    hslColor.lightness * (1 - darkBlend), // 显著降低亮度
  ).toColor();

  // 创建浅色变体
  // 增加亮度，保持一些原始颜色的色相，降低饱和度
  Color lightVariant = HSLColor.fromAHSL(
    hslColor.alpha,
    hslColor.hue,
    hslColor.saturation * (1 - lightBlend * 0.7), // 显著降低饱和度
    hslColor.lightness + (1 - hslColor.lightness) * lightBlend, // 增加亮度
  ).toColor();

  return (darkVariant: darkVariant, lightVariant: lightVariant);
}

/// 根据给定颜色生成深色变体
/// [baseColor] 基础颜色
/// [blend] 混合系数，值越大，越接近纯黑色，范围[0,1]
Color getDarkVariant(Color baseColor, {double blend = 0.7}) {
  return generateColorVariants(baseColor, darkBlend: blend).darkVariant;
}

/// 根据给定颜色生成浅色变体
/// [baseColor] 基础颜色
/// [blend] 混合系数，值越大，越接近纯白色，范围[0,1]
Color getLightVariant(Color baseColor, {double blend = 0.7}) {
  return generateColorVariants(baseColor, lightBlend: blend).lightVariant;
}

/// 计算感知亮度
double perceivedBrightness(Color color) {
  return 0.299 * color.r * 255 + 0.587 * color.g * 255 + 0.114 * color.b * 255;
}

/// 获取最暗的颜色（亮度最低）
Color getDarkestColor(List<Color> colors) {
  if (colors.isEmpty) {
    throw ArgumentError('颜色列表不能为空');
  }

  return colors.reduce((darkest, current) {
    return perceivedBrightness(current) < perceivedBrightness(darkest)
        ? current
        : darkest;
  });
}

/// 获取最亮的颜色（亮度最高）
Color getBrightestColor(List<Color> colors) {
  if (colors.isEmpty) {
    throw ArgumentError('颜色列表不能为空');
  }

  return colors.reduce((brightest, current) {
    return perceivedBrightness(current) > perceivedBrightness(brightest)
        ? current
        : brightest;
  });
}
