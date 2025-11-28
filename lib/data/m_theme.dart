import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/services/boxes/course_box.dart';
import 'package:swustmeow/utils/color.dart';

import '../services/boxes/common_box.dart';

class MTheme {
  static List<Color> get primaryColors {
    final colorInt = CommonBox.get('themeColor') as int?;
    return generatePrimaryColors(Color(colorInt ?? 0xFF1B7ADE));
  }

  static bool get courseTableUseWhiteFont =>
      CourseBox.get('useWhiteFont') as bool? ?? false;

  static Color get primary0 => primaryColors[0];

  static Color get primary1 => primaryColors[1];

  static Color get primary2 => primaryColors[2];

  static Color get primary3 => primaryColors[3];

  static Color get primary4 => primaryColors[4];

  static Color get primary5 => primaryColors[5];

  static ({Color darkVariant, Color lightVariant}) get variants =>
      generateColorVariants(primary2);

  static Color get primaryText => Colors.black;

  static Color get backgroundText =>
      primary2.computeLuminance() >= 0.6 ? variants.darkVariant : Colors.white;

  static Color get courseTableText => courseTableUseWhiteFont
      ? getBrightestColor(courseTablePalette ?? [Colors.white])
      : getDarkestColor(courseTablePalette ?? [Colors.black]);

  static String? get courseTableImagePath =>
      CourseBox.get('backgroundImage') as String?;

  static List<Color>? get courseTablePalette =>
      (CourseBox.get('colorPalette') as List<dynamic>?)
          ?.map((x) => Color(x as int))
          .toList();

  static const disabled = Color.fromRGBO(209, 213, 219, 1);

  static const border = Color.fromRGBO(229, 231, 235, 1);

  static const hovered = Color.fromRGBO(243, 244, 246, 1);

  static const radius = 16.0;

  static final theme = FThemes.zinc.light;

  static FThemeData get themeData {
    final borderRadius = BorderRadius.circular(radius);
    final tileStyle = theme.tileGroupStyle.tileStyle.copyWith(
      border: Border.all(color: border),
      focusedBorder: Border.all(color: primary3),
      borderRadius: borderRadius,
      enabledBackgroundColor: Colors.white,
      enabledHoveredBackgroundColor: hovered,
      disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
    );
    final tileGroupStyle = theme.tileGroupStyle.copyWith(
      borderColor: MTheme.border,
      borderRadius: borderRadius,
      tileStyle: tileStyle,
    );

    return FThemeData(
      colorScheme: theme.colorScheme.copyWith(
        border: border,
      ),
      typography: theme.typography.copyWith(
        base: theme.typography.base.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      style: theme.style.copyWith(
        focusedOutlineStyle: theme.style.focusedOutlineStyle
            .copyWith(color: border, borderRadius: borderRadius),
        borderRadius: borderRadius,
      ),
      accordionStyle: theme.accordionStyle,
      alertStyles: theme.alertStyles,
      avatarStyle: theme.avatarStyle,
      badgeStyles: theme.badgeStyles,
      bottomNavigationBarStyle: theme.bottomNavigationBarStyle,
      breadcrumbStyle: theme.breadcrumbStyle,
      buttonStyles: theme.buttonStyles.copyWith(
        primary: theme.buttonStyles.primary.copyWith(
          enabledBoxDecoration:
              theme.buttonStyles.primary.enabledBoxDecoration.copyWith(
            color: primary2,
            borderRadius: borderRadius,
          ),
          enabledHoverBoxDecoration:
              theme.buttonStyles.primary.enabledHoverBoxDecoration.copyWith(
            color: hovered,
            borderRadius: borderRadius,
          ),
          disabledBoxDecoration:
              theme.buttonStyles.primary.disabledBoxDecoration.copyWith(
            color: disabled,
            borderRadius: borderRadius,
          ),
        ),
        secondary: theme.buttonStyles.secondary.copyWith(
          enabledBoxDecoration:
              theme.buttonStyles.secondary.enabledBoxDecoration.copyWith(
            borderRadius: borderRadius,
          ),
          enabledHoverBoxDecoration:
              theme.buttonStyles.secondary.enabledHoverBoxDecoration.copyWith(
            color: hovered,
            borderRadius: borderRadius,
          ),
          disabledBoxDecoration:
              theme.buttonStyles.secondary.disabledBoxDecoration.copyWith(
            color: disabled,
            borderRadius: borderRadius,
          ),
        ),
        outline: theme.buttonStyles.outline.copyWith(
          enabledBoxDecoration:
              theme.buttonStyles.outline.enabledBoxDecoration.copyWith(
            border: Border.all(color: border),
            borderRadius: borderRadius,
          ),
          enabledHoverBoxDecoration:
              theme.buttonStyles.outline.enabledHoverBoxDecoration.copyWith(
            color: border.withDarkness(0.1),
            borderRadius: borderRadius,
          ),
          disabledBoxDecoration:
              theme.buttonStyles.outline.disabledBoxDecoration.copyWith(
            border: Border.all(color: disabled),
            borderRadius: borderRadius,
          ),
        ),
        destructive: theme.buttonStyles.destructive.copyWith(
          enabledBoxDecoration:
              theme.buttonStyles.destructive.enabledBoxDecoration.copyWith(
            borderRadius: borderRadius,
          ),
          enabledHoverBoxDecoration:
              theme.buttonStyles.destructive.enabledHoverBoxDecoration.copyWith(
            borderRadius: borderRadius,
          ),
          disabledBoxDecoration:
              theme.buttonStyles.destructive.disabledBoxDecoration.copyWith(
            borderRadius: borderRadius,
          ),
        ),
      ),
      calendarStyle: theme.calendarStyle,
      cardStyle: theme.cardStyle,
      checkboxStyle: theme.checkboxStyle.copyWith(
        enabledStyle: theme.checkboxStyle.enabledStyle.copyWith(
          borderColor: primary2,
          checkedBackgroundColor: primary2,
          descriptionTextStyle:
              theme.checkboxStyle.enabledStyle.descriptionTextStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        disabledStyle: theme.checkboxStyle.disabledStyle.copyWith(
          borderColor: disabled,
          checkedBackgroundColor: disabled,
          descriptionTextStyle:
              theme.checkboxStyle.disabledStyle.descriptionTextStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      datePickerStyle: theme.datePickerStyle,
      dialogStyle: theme.dialogStyle.copyWith(
        decoration: theme.dialogStyle.decoration.copyWith(
          borderRadius: borderRadius,
        ),
      ),
      dividerStyles: theme.dividerStyles,
      headerStyle: theme.headerStyle,
      labelStyles: theme.labelStyles,
      lineCalendarStyle: theme.lineCalendarStyle.copyWith(
        selectedItemStyle: theme.lineCalendarStyle.selectedItemStyle.copyWith(
          todayIndicatorColor: Colors.white,
          decoration:
              theme.lineCalendarStyle.selectedItemStyle.decoration.copyWith(
            borderRadius: borderRadius,
            color: primary2,
          ),
          focusedDecoration: theme
              .lineCalendarStyle.selectedItemStyle.focusedDecoration
              .copyWith(
            borderRadius: borderRadius,
            color: primary2,
          ),
        ),
        selectedHoveredItemStyle:
            theme.lineCalendarStyle.selectedHoveredItemStyle.copyWith(
          todayIndicatorColor: Colors.white,
          decoration: theme
              .lineCalendarStyle.selectedHoveredItemStyle.decoration
              .copyWith(
            borderRadius: borderRadius,
            color: hovered,
          ),
          focusedDecoration: theme
              .lineCalendarStyle.selectedHoveredItemStyle.focusedDecoration
              .copyWith(
            borderRadius: borderRadius,
            color: hovered,
          ),
        ),
        unselectedItemStyle:
            theme.lineCalendarStyle.unselectedItemStyle.copyWith(
          todayIndicatorColor: primary2,
          decoration:
              theme.lineCalendarStyle.unselectedItemStyle.decoration.copyWith(
            border: Border.all(color: border),
            borderRadius: borderRadius,
          ),
          focusedDecoration: theme
              .lineCalendarStyle.unselectedItemStyle.focusedDecoration
              .copyWith(
            border: Border.all(color: border),
            borderRadius: borderRadius,
          ),
        ),
        unselectedHoveredItemStyle:
            theme.lineCalendarStyle.unselectedHoveredItemStyle.copyWith(
          todayIndicatorColor: primary2,
          decoration: theme
              .lineCalendarStyle.unselectedHoveredItemStyle.decoration
              .copyWith(
            border: Border.all(color: border),
            borderRadius: borderRadius,
            color: hovered,
          ),
          focusedDecoration: theme
              .lineCalendarStyle.unselectedHoveredItemStyle.focusedDecoration
              .copyWith(
            border: Border.all(color: border),
            borderRadius: borderRadius,
            color: hovered,
          ),
        ),
      ),
      pickerStyle: theme.pickerStyle,
      popoverStyle: theme.popoverStyle.copyWith(
        decoration: theme.popoverStyle.decoration.copyWith(
          border: Border.all(color: border),
          borderRadius: borderRadius,
        ),
      ),
      popoverMenuStyle: theme.popoverMenuStyle,
      progressStyle: theme.progressStyle,
      radioStyle: theme.radioStyle,
      resizableStyle: theme.resizableStyle,
      scaffoldStyle: theme.scaffoldStyle,
      selectGroupStyle: theme.selectGroupStyle,
      selectMenuTileStyle: theme.selectMenuTileStyle.copyWith(
        tileStyle: tileStyle,
        menuStyle: theme.selectMenuTileStyle.menuStyle.copyWith(
          decoration: theme.selectMenuTileStyle.menuStyle.decoration.copyWith(
            border: Border.all(color: border),
            borderRadius: borderRadius,
          ),
          tileGroupStyle: tileGroupStyle,
        ),
      ),
      sheetStyle: theme.sheetStyle,
      sliderStyles: theme.sliderStyles,
      switchStyle: theme.switchStyle.copyWith(
          enabledStyle: theme.switchStyle.enabledStyle.copyWith(
            checkedColor: primary2,
          ),
          disabledStyle: theme.switchStyle.disabledStyle.copyWith(
            checkedColor: primary2.withValues(alpha: 0.3),
          )),
      tabsStyle: theme.tabsStyle.copyWith(
        decoration: theme.tabsStyle.decoration.copyWith(
          color: Colors.white,
          border: Border.all(color: Colors.transparent, width: 0.0),
          borderRadius: borderRadius,
        ),
        indicatorDecoration: theme.tabsStyle.indicatorDecoration.copyWith(
          color: primary2,
          borderRadius: borderRadius,
        ),
        selectedLabelTextStyle: theme.tabsStyle.selectedLabelTextStyle.copyWith(
          color: Colors.white,
        ),
      ),
      textFieldStyle: theme.textFieldStyle.copyWith(
        cursorColor: primary1,
        enabledStyle: theme.textFieldStyle.enabledStyle.copyWith(
          unfocusedStyle:
              theme.textFieldStyle.enabledStyle.unfocusedStyle.copyWith(
            color: border,
            radius: borderRadius,
          ),
          focusedStyle:
              theme.textFieldStyle.enabledStyle.unfocusedStyle.copyWith(
            color: primary1,
            radius: borderRadius,
          ),
        ),
        disabledStyle: theme.textFieldStyle.disabledStyle.copyWith(
          unfocusedStyle:
              theme.textFieldStyle.disabledStyle.unfocusedStyle.copyWith(
            color: border.withDarkness(0.1),
            radius: borderRadius,
          ),
          focusedStyle:
              theme.textFieldStyle.disabledStyle.unfocusedStyle.copyWith(
            color: primary1.withDarkness(0.1),
            radius: borderRadius,
          ),
        ),
        errorStyle: theme.textFieldStyle.errorStyle.copyWith(
          unfocusedStyle:
              theme.textFieldStyle.errorStyle.unfocusedStyle.copyWith(
            radius: borderRadius,
          ),
          focusedStyle: theme.textFieldStyle.errorStyle.unfocusedStyle.copyWith(
            radius: borderRadius,
          ),
        ),
      ),
      tooltipStyle: theme.tooltipStyle,
      tileGroupStyle: tileGroupStyle,
    );
  }
}
