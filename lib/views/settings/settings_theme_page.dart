import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/services/boxes/common_box.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/color.dart';

import '../../services/color_service.dart';

class SettingsThemePage extends StatefulWidget {
  final Function() onSelectColor;

  const SettingsThemePage({
    super.key,
    required this.onSelectColor,
  });

  @override
  State<SettingsThemePage> createState() => _SettingsThemePageState();
}

class _SettingsThemePageState extends State<SettingsThemePage> {
  Color? _selectedColor;
  bool _isSaving = false;

  // 预设主题色列表
  final List<Color> _presetColors = [
    const Color(0xFF1B7ADE), // 默认蓝色
    const Color(0xFF00BFA5), // 薄荷绿
    const Color(0xFFFF5252), // 珊瑚红
    const Color(0xFF7E57C2), // 丁香紫
    const Color(0xFFFFAB40), // 琥珀橙
    const Color(0xFF1565C0), // 普鲁士蓝
    const Color(0xFF00ACC1), // 青绿色
    const Color(0xFFFFD740), // 玉米黄
    const Color(0xFF303F9F), // 靛蓝色
    const Color(0xFF558B2F), // 苔藓绿
    const Color(0xFFC62828), // 赭石红
    const Color(0xFF6A1B9A), // 梅子紫
    const Color(0xFFE6A8A8), // 玫瑰金
    const Color(0xFF4CAF50), // 深橄榄绿
    const Color(0xFF455A64), // 深灰色
    const Color(0xFF673AB7), // 绛紫色
    const Color(0xFFEC407A), // 粉红色
    const Color(0xFF795548), // 青铜色
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    try {
      // 加载当前主题色
      final colorInt = CommonBox.get('themeColor') as int?;

      setState(() {
        _selectedColor = Color(colorInt ?? 0xFF1B7ADE);
      });
    } catch (e) {
      showErrorToast('加载设置失败: $e');
    }
  }

  // 保存主题设置
  Future<void> _saveThemeSettings() async {
    if (_selectedColor == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await CommonBox.put('themeColor', _selectedColor?.toInt());
      ColorService.reload();
      widget.onSelectColor();

      showSuccessToast('主题设置已保存');
    } catch (e) {
      showErrorToast('保存失败: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '主题设置'),
      content: Stack(
        children: [
          // 主要内容区域
          ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              _buildThemeSelector(),
              const SizedBox(height: 16),
              _buildColorPreview(),
            ],
          ),

          // 悬浮按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveThemeSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MTheme.primary2,
                    foregroundColor: MTheme.backgroundText,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MTheme.radius),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          '应用主题',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 主题色选择器
  Widget _buildThemeSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.palette,
                size: 18,
                color: MTheme.primaryText,
              ),
              SizedBox(width: 8),
              Text(
                '预设主题色',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            padding: EdgeInsets.zero,
            itemCount: _presetColors.length,
            itemBuilder: (context, index) {
              final color = _presetColors[index];
              final isSelected = _selectedColor == color;

              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreview() {
    if (_selectedColor == null) return SizedBox.shrink();

    // 根据选中的颜色生成色卡系列
    final colorSeries = generatePrimaryColors(_selectedColor!);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.swatchbook,
                size: 18,
                color: MTheme.primaryText,
              ),
              SizedBox(width: 8),
              Text(
                '主题色预览',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildColorCards(colorSeries),
        ],
      ),
    );
  }

  Widget _buildColorCards(List<Color> colors) {
    final titles = ['极深', '较深', '标准', '较浅', '浅色', '最浅'];

    return Column(
      children: [
        for (int i = 0; i < colors.length; i++)
          _buildColorCard(colors[i], titles[i], i == 2),
      ],
    );
  }

  Widget _buildColorCard(Color color, String title, bool isMain) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: MTheme.primaryText,
                      ),
                    ),
                    if (isMain)
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '主色调',
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  _colorToHex(color),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 将颜色转换为十六进制格式
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
