import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swustmeow/components/simple_setting_item.dart';
import 'package:swustmeow/components/simple_settings_group.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/color_mode.dart';
import 'package:swustmeow/services/boxes/course_box.dart';
import 'package:swustmeow/utils/color.dart';
import 'package:swustmeow/utils/widget.dart';

import '../../utils/common.dart';

class CourseTableThemeSettingsPage extends StatefulWidget {
  final Function() onRefresh;

  const CourseTableThemeSettingsPage({super.key, required this.onRefresh});

  @override
  State<CourseTableThemeSettingsPage> createState() =>
      _CourseTableThemeSettingsPageState();
}

class _CourseTableThemeSettingsPageState
    extends State<CourseTableThemeSettingsPage> {
  double _cardOpacity = 1.0;
  bool _enableBackgroundBlur = false;
  double _backgroundBlurSigma = 5.0;
  ColorMode _courseColorMode = ColorMode.colorful;
  bool _hasPalette = false;
  late final FSliderController _cardOpacityController;
  late final FSliderController _backgroundBlurSigmaController;
  bool _isImageLoading = false;
  String? _backgroundImagePath;
  final ImagePicker _picker = ImagePicker();
  bool _useWhiteFont = false;
  List<Color> _imageColors = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();

    _cardOpacityController = FContinuousSliderController(
      allowedInteraction: FSliderInteraction.tapAndSlideThumb,
      selection: FSliderSelection(
        max: _cardOpacity,
        extent: (min: 0.1, max: 1.0),
      ),
    );

    _backgroundBlurSigmaController = FContinuousSliderController(
      allowedInteraction: FSliderInteraction.tapAndSlideThumb,
      selection: FSliderSelection(
        max: _backgroundBlurSigma / 30.0,
        extent: (min: 0.0, max: 1.0),
      ),
    );

    _cardOpacityController.addListener(() {
      final value = _cardOpacityController.selection.offset.max;
      setState(() {
        _cardOpacity = value;
      });
      CourseBox.put('cardOpacity', _cardOpacity);
      widget.onRefresh();
    });

    _backgroundBlurSigmaController.addListener(() {
      final value = _backgroundBlurSigmaController.selection.offset.max * 30.0;
      setState(() {
        _backgroundBlurSigma = value;
      });
      CourseBox.put('backgroundBlurSigma', _backgroundBlurSigma);
      widget.onRefresh();
    });
  }

  Future<void> _loadSettings() async {
    setState(() => _isImageLoading = true);

    // 加载已保存的设置
    final cardOpacity = CourseBox.get('cardOpacity') as double?;
    final enableBackgroundBlur = CourseBox.get('enableBackgroundBlur') as bool?;
    final backgroundBlurSigma = CourseBox.get('backgroundBlurSigma') as double?;
    final colorMode = CourseBox.get('courseColorMode') as ColorMode?;
    final hasPalette = CourseBox.get('colorPalette') != null;
    final imagePath = CourseBox.get('backgroundImage') as String?;
    final useWhiteFont = CourseBox.get('useWhiteFont') as bool?;
    final colorValues = CourseBox.get('colorPalette') as List<dynamic>?;

    setState(() {
      _cardOpacity = cardOpacity ?? 1.0;
      _enableBackgroundBlur = enableBackgroundBlur ?? false;
      _backgroundBlurSigma = backgroundBlurSigma ?? 5.0;
      _courseColorMode = colorMode ?? ColorMode.colorful;
      _hasPalette = hasPalette;
      _backgroundImagePath = imagePath;
      _useWhiteFont = useWhiteFont ?? false;
      _imageColors = colorValues != null
          ? colorValues.map((value) => Color(value as int)).toList()
          : [];
    });

    if (imagePath != null && _imageColors.isEmpty) {
      await _generatePaletteFromImage(imagePath);
    }

    _refresh(() => _isImageLoading = false);
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '课程表样式设置'),
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: joinGap(
        gap: 8,
        axis: Axis.vertical,
        widgets: [
          _buildImageSelector(),
          _buildAppearanceSettings(),
          _buildColorModeSettings(),
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    return SimpleSettingsGroup(
      title: '课程卡片样式',
      children: [
        SimpleSettingItem(
          title: '卡片透明度',
          subtitle: '调整课程卡片的透明度',
          icon: FontAwesomeIcons.circleHalfStroke,
          suffix: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${(_cardOpacity * 100).toInt()}%',
              style: TextStyle(
                color: MTheme.primary2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: FSlider(controller: _cardOpacityController),
        ),
        if (_backgroundImagePath != null) ...[
          SimpleSettingItem(
            title: '背景模糊效果',
            subtitle: '启用背景高斯模糊效果（注意：可能影响性能）',
            icon: FontAwesomeIcons.image,
            suffix: FSwitch(
              value: _enableBackgroundBlur,
              onChange: (value) async {
                await CourseBox.put('enableBackgroundBlur', value);
                setState(() {
                  _enableBackgroundBlur = value;
                });
                widget.onRefresh();
              },
            ),
          ),
          if (_enableBackgroundBlur) ...[
            SimpleSettingItem(
              title: '背景模糊程度',
              subtitle: '调整背景的模糊效果强度',
              icon: FontAwesomeIcons.sliders,
              suffix: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${_backgroundBlurSigma.toInt()}',
                  style: TextStyle(
                    color: MTheme.primary2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FSlider(controller: _backgroundBlurSigmaController),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildColorModeSettings() {
    final items = [
      SimpleDropdownItem<ColorMode>(
        value: ColorMode.theme,
        label: '统一使用主题色',
        icon:
            Icon(Icons.format_color_fill, color: MTheme.primaryText, size: 16),
      ),
      SimpleDropdownItem<ColorMode>(
        value: ColorMode.colorful,
        label: '使用自动生成的颜色',
        icon: Icon(Icons.palette, color: MTheme.primaryText, size: 16),
      ),
      if (_hasPalette)
        SimpleDropdownItem<ColorMode>(
          value: ColorMode.palette,
          label: '使用自定义背景图中的调色盘',
          icon: Icon(Icons.image, color: MTheme.primaryText, size: 16),
        ),
    ];

    return SimpleSettingsGroup(
      title: '课程颜色模式',
      children: [
        SimpleSettingItem.dropdown<ColorMode>(
          title: '课程卡片颜色',
          subtitle: '选择课程卡片的颜色显示方式',
          icon: FontAwesomeIcons.palette,
          value: _courseColorMode,
          items: items,
          onChanged: _updateCourseColorMode,
          dropdownWidth: 220,
        ),
      ],
    );
  }

  void _updateCourseColorMode(ColorMode mode) {
    CourseBox.put('courseColorMode', mode);
    widget.onRefresh();

    if (!mounted) return;
    setState(() {
      _courseColorMode = mode;
    });
  }

  // 图片选择器
  Widget _buildImageSelector() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '背景图片',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
            ),
            Spacer(),
            if (_backgroundImagePath != null)
              GestureDetector(
                onTap: _removeBackground,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline,
                          size: 14, color: Colors.red.shade700),
                      SizedBox(width: 4),
                      Text(
                        '移除',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: MTheme.border),
            borderRadius: BorderRadius.circular(MTheme.radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_backgroundImagePath != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(_backgroundImagePath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: _isImageLoading ? null : _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                        // style: BorderStyle.dashed,
                      ),
                    ),
                    child: _isImageLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  MTheme.primary2),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 32,
                                color: Colors.grey.shade500,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '选择图片',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '支持从图片中提取主题色',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.font,
                    size: 16,
                    color: MTheme.primaryText,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '字体颜色',
                    style: TextStyle(
                      fontSize: 14,
                      color: MTheme.primaryText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        setState(() => _useWhiteFont = false);
                        await CourseBox.put('useWhiteFont', false);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_useWhiteFont
                              ? MTheme.primary2.withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !_useWhiteFont
                                ? MTheme.primary2
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              !_useWhiteFont
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 16,
                              color: !_useWhiteFont
                                  ? MTheme.primary2
                                  : Colors.grey.shade400,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '黑色字体',
                              style: TextStyle(
                                color: !_useWhiteFont
                                    ? MTheme.primary2
                                    : Colors.grey.shade600,
                                fontWeight: !_useWhiteFont
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        setState(() => _useWhiteFont = true);
                        await CourseBox.put('useWhiteFont', true);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _useWhiteFont
                              ? MTheme.primary2.withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _useWhiteFont
                                ? MTheme.primary2
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _useWhiteFont
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 16,
                              color: _useWhiteFont
                                  ? MTheme.primary2
                                  : Colors.grey.shade400,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '白色字体',
                              style: TextStyle(
                                color: _useWhiteFont
                                    ? MTheme.primary2
                                    : Colors.grey.shade600,
                                fontWeight: _useWhiteFont
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_backgroundImagePath != null) ...[
                SizedBox(height: 16),
                _buildImageColorPalette(),
                SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 图片颜色选择器
  Widget _buildImageColorPalette() {
    if (_imageColors.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
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
              '配色板',
              style: TextStyle(
                fontSize: 14,
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
          itemCount: _imageColors.length,
          itemBuilder: (context, index) {
            final color = _imageColors[index];

            return Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 移除背景图片
  Future<void> _removeBackground() async {
    showAdaptiveDialog(
      context: context,
      builder: (context) => FDialog(
        title: Text('移除背景图片'),
        body: Text('确定要移除当前背景图片吗？这将同时移除从图片提取的颜色。'),
        direction: Axis.horizontal,
        actions: [
          FButton(
            label: Text('取消'),
            onPress: () => Navigator.pop(context),
            style: FButtonStyle.ghost,
          ),
          FButton(
            label: Text('确定'),
            onPress: () async {
              Navigator.pop(context);

              if (_backgroundImagePath != null) {
                final File file = File(_backgroundImagePath!);
                if (await file.exists()) {
                  await file.delete();
                }

                setState(() {
                  _backgroundImagePath = null;
                  _imageColors = [];
                });

                await CourseBox.put('backgroundImage', null);
                await CourseBox.put('colorPalette', null);

                showSuccessToast('背景图片已移除');
              }
            },
            style: context.theme.buttonStyles.primary.copyWith(
              enabledBoxDecoration: context
                  .theme.buttonStyles.primary.enabledBoxDecoration
                  .copyWith(color: MTheme.primary2),
            ),
          ),
        ],
      ),
    );
  }

  // 选择图片
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      // 将图片复制到应用目录
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'theme_background_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = '${directory.path}/$fileName';

      // 删除旧图片文件（如果存在）
      if (_backgroundImagePath != null) {
        final File oldFile = File(_backgroundImagePath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // 复制图片文件
      final File imageFile = File(image.path);
      await imageFile.copy(savedImagePath);

      setState(() {
        _backgroundImagePath = savedImagePath;
        _isImageLoading = true;
      });

      // 生成配色方案
      await _generatePaletteFromImage(savedImagePath);

      // 保存路径到设置
      await CourseBox.put('backgroundImage', savedImagePath);

      setState(() => _isImageLoading = false);
      showSuccessToast('背景图片已设置');
    } catch (e) {
      setState(() => _isImageLoading = false);
      showErrorToast('选择图片失败: $e');
    }
  }

  // 从图片生成颜色方案
  Future<void> _generatePaletteFromImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('图片文件不存在');
      }

      final ImageProvider imageProvider = FileImage(imageFile);
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 30,
      );

      final List<Color> colors = [];

      bool isColorSuitable(Color color) {
        final hslColor = HSLColor.fromColor(color);
        return hslColor.lightness <= 0.7 && hslColor.lightness >= 0.2;
      }

      // 添加提取的主要颜色，过滤掉明度过高的颜色
      colors.addAll(
        paletteGenerator.colors.where(isColorSuitable).toList(),
      );

      // 如果提取的颜色不足20种，生成更多变体
      if (colors.length < 20) {
        // 添加主要颜色的明暗变体
        final List<Color> variants = [];
        for (var color in colors) {
          final hslColor = HSLColor.fromColor(color);

          // 添加明亮变体（但确保明度不超过0.7）
          if (hslColor.lightness - 0.15 <= 0.7 &&
              hslColor.lightness - 0.15 >= 0.2) {
            variants.add(HSLColor.fromColor(color)
                .withLightness((hslColor.lightness - 0.15).clamp(0.2, 0.7))
                .toColor());
          }

          // 添加暗色变体
          variants.add(HSLColor.fromColor(color)
              .withLightness((hslColor.lightness - 0.25).clamp(0.2, 0.5))
              .toColor());
        }

        // 添加变体，但确保颜色足够不同
        for (var color in variants) {
          if (colors.length >= 24) break;

          // 再次检查明度
          if (!isColorSuitable(color)) continue;

          // 检查是否与现有颜色太相似
          bool tooSimilar = false;
          for (var existingColor in colors) {
            if (_colorDistance(color, existingColor) < 25) {
              tooSimilar = true;
              break;
            }
          }

          if (!tooSimilar) {
            colors.add(color);
          }
        }
      }

      setState(() {
        _imageColors = colors.take(24).toList();
      });

      // 保存提取的颜色到课表设置
      final colorValues = _imageColors.map((color) => color.toInt()).toList();
      await CourseBox.put('colorPalette', colorValues);
    } catch (e) {
      showErrorToast('生成颜色方案失败: $e');
    }
  }

  // 计算两个颜色之间的距离（欧几里得距离）
  double _colorDistance(Color c1, Color c2) {
    final r = c1.r - c2.r;
    final g = c1.g - c2.g;
    final b = c1.b - c2.b;
    return (r * r + g * g + b * b) / 255;
  }
}
