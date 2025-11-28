import 'package:flutter/material.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/services/boxes/common_box.dart';
import 'package:swustmeow/entity/color_mode.dart';
import 'package:swustmeow/components/simple_settings_group.dart';
import 'package:swustmeow/components/simple_setting_item.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/services/color_service.dart';

class SettingsAppearancePage extends StatefulWidget {
  final Function() onSelectColor;

  const SettingsAppearancePage({
    super.key,
    required this.onSelectColor,
  });

  @override
  State<SettingsAppearancePage> createState() => _SettingsAppearancePageState();
}

class _SettingsAppearancePageState extends State<SettingsAppearancePage> {
  ColorMode _toolAccountColorMode = ColorMode.colorful;
  bool _hasPalette = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final toolbarMode =
        CommonBox.get('toolAccountColorMode') as ColorMode?;
    final hasPalette = CommonBox.get('colorPalette') != null;

    setState(() {
      _toolAccountColorMode = toolbarMode ?? ColorMode.colorful;
      _hasPalette = hasPalette;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '外观设置'),
      content: SafeArea(
        top: false,
        bottom: true,
        child: ListView(
          padding: EdgeInsets.all(MTheme.radius),
          children: [
            _buildToolbarColorSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarColorSection() {
    final items = [
      SimpleDropdownItem<ColorMode>(
        value: ColorMode.theme,
        label: '统一使用主题色',
        icon:
            Icon(Icons.format_color_fill, color: MTheme.primaryText, size: 16),
      ),
      SimpleDropdownItem<ColorMode>(
        value: ColorMode.colorful,
        label: '使用预设彩色方案',
        icon: Icon(Icons.palette, color: MTheme.primaryText, size: 16),
      ),
      if (_hasPalette)
        SimpleDropdownItem<ColorMode>(
          value: ColorMode.palette,
          label: '使用自定义图片提取配色',
          icon: Icon(Icons.image, color: MTheme.primaryText, size: 16),
        ),
    ];

    return SimpleSettingsGroup(
      title: '工具栏',
      children: [
        SimpleSettingItem.dropdown<ColorMode>(
          title: '工具与账号颜色模式',
          subtitle: '选择工具与账号图标的颜色显示方式',
          icon: FontAwesomeIcons.palette,
          value: _toolAccountColorMode,
          items: items,
          onChanged: _updateToolAccountColorMode,
          dropdownWidth: 220,
        ),
      ],
    );
  }

  void _updateToolAccountColorMode(ColorMode mode) {
    CommonBox.put('toolAccountColorMode', mode);
    ColorService.reload();
    widget.onSelectColor();

    if (!mounted) return;
    setState(() {
      _toolAccountColorMode = mode;
    });
  }
}
