import 'package:flutter/material.dart';
import 'package:swustmeow/utils/color.dart';

import '../entity/color_mode.dart';
import 'boxes/common_box.dart';

class ColorService {
  static ColorMode toolAccountColorMode = ColorMode.colorful;

  static Color defaultSoaColor = Colors.blue;
  static Color defaultYktColor = Colors.lightBlue;
  static Color defaultApartmentColor = Colors.green;
  static Color defaultDuifeneColor = Colors.orange;
  static Color defaultChaoXingColor = Colors.red;
  static Color defaultMoreColor = Colors.grey;

  static ValueNotifier<Color> soaColor = ValueNotifier(defaultSoaColor);
  static ValueNotifier<Color> yktColor = ValueNotifier(defaultYktColor);
  static ValueNotifier<Color> apartmentColor =
      ValueNotifier(defaultApartmentColor);
  static ValueNotifier<Color> duifeneColor = ValueNotifier(defaultDuifeneColor);
  static ValueNotifier<Color> chaoxingColor =
      ValueNotifier(defaultChaoXingColor);
  static ValueNotifier<Color> moreColor = ValueNotifier(defaultMoreColor);

  static void reload() {
    final themeColor = Color(CommonBox.get('themeColor') as int? ?? 0xFF1B7ADE);

    final mode = CommonBox.get('toolAccountColorMode') as ColorMode?;
    toolAccountColorMode = mode ?? ColorMode.colorful;

    final palette = CommonBox.get('colorPalette') as List<int>?;

    switch (toolAccountColorMode) {
      case ColorMode.colorful:
        soaColor.value = defaultSoaColor;
        yktColor.value = defaultYktColor;
        apartmentColor.value = defaultApartmentColor;
        duifeneColor.value = defaultDuifeneColor;
        chaoxingColor.value = defaultChaoXingColor;
        moreColor.value = defaultMoreColor;
      case ColorMode.theme:
        soaColor.value = themeColor;
        yktColor.value = themeColor;
        apartmentColor.value = themeColor;
        duifeneColor.value = themeColor;
        chaoxingColor.value = themeColor;
        moreColor.value = themeColor;
      case ColorMode.palette:
        if (palette != null && palette.isNotEmpty) {
          soaColor.value = getColorFromPaletteWithStringAndBrightness('soa')!;
          yktColor.value = getColorFromPaletteWithStringAndBrightness('ykt')!;
          apartmentColor.value =
              getColorFromPaletteWithStringAndBrightness('apartment')!;
          duifeneColor.value =
              getColorFromPaletteWithStringAndBrightness('duifene')!;
          chaoxingColor.value =
              getColorFromPaletteWithStringAndBrightness('chaoxing')!;
          moreColor.value = defaultMoreColor;
        }
    }
  }
}
