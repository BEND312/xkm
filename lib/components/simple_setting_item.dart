import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';

import '../data/m_theme.dart';

class SimpleSettingItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Function()? onPress;
  final Widget? suffix;
  final bool hasSuffix;
  final Color? color;

  const SimpleSettingItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onPress,
    this.suffix,
    this.hasSuffix = true,
    this.color,
  });

  /// 创建一个带下拉菜单的设置项
  static Widget dropdown<T>({
    required String title,
    String? subtitle,
    required IconData icon,
    required T value,
    required List<SimpleDropdownItem<T>> items,
    required Function(T) onChanged,
    double? dropdownWidth,
    Color? color,
  }) {
    return _DropdownSettingItem<T>(
      title: title,
      subtitle: subtitle,
      icon: icon,
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownWidth: dropdownWidth,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FTile(
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              maxLines: 999,
              style: TextStyle(
                color: (color ?? Colors.black).withValues(alpha: 0.6),
                fontSize: 11,
              ),
            )
          : null,
      prefixIcon: Container(
        // padding: EdgeInsets.all(8),
        // decoration: BoxDecoration(
        //   color: MTheme.primary2.withValues(alpha: 0.1),
        //   borderRadius: BorderRadius.circular(8),
        // ),
        child: SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: FaIcon(
              icon,
              color: color ?? Colors.black,
              size: 14,
            ),
          ),
        ),
      ),
      suffixIcon: hasSuffix
          ? suffix ??
              FIcon(
                FAssets.icons.chevronRight,
                size: 14,
                color: Colors.grey,
              )
          : null,
      onPress: onPress,
      style: context.theme.tileGroupStyle.tileStyle.copyWith(
        border: Border.all(color: Colors.transparent, width: 0),
      ),
    );
  }
}

class _DropdownSettingItem<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final T value;
  final List<SimpleDropdownItem<T>> items;
  final Function(T) onChanged;
  final double? dropdownWidth;
  final Color? color;

  const _DropdownSettingItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.dropdownWidth,
    this.color,
  });

  @override
  State<_DropdownSettingItem<T>> createState() =>
      _DropdownSettingItemState<T>();
}

class _DropdownSettingItemState<T> extends State<_DropdownSettingItem<T>>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heightAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    // 确保在页面销毁时关闭下拉菜单
    if (_overlayEntry?.mounted == true) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = widget.dropdownWidth ?? 220; // 默认宽度220

    // 计算右侧对齐位置（与下拉箭头对齐）
    final right = screenWidth - (offset.dx + size.width);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _closeDropdown,
          behavior: HitTestBehavior.translucent,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  right: right + 16, // 右侧保留16的边距
                  top: offset.dy + size.height + 8,
                  width: dropdownWidth,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: 250 * _heightAnimation.value,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(MTheme.radius),
                            border: Border.all(color: MTheme.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(MTheme.radius),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _buildDropdownItems(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _animationController.forward();
  }

  void _closeDropdown() {
    if (!_isOpen) return;

    setState(() => _isOpen = false);
    _animationController.reverse().then((_) {
      if (_overlayEntry?.mounted == true) {
        _overlayEntry?.remove();
      }
    });
  }

  Widget _buildDropdownItems() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: widget.items.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: MTheme.border),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isSelected = widget.value == item.value;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _closeDropdown();
              Future.delayed(const Duration(milliseconds: 100), () {
                widget.onChanged(item.value);
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    item.icon!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? MTheme.primaryText : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check, color: MTheme.primaryText, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getSelectedText() {
    for (var item in widget.items) {
      if (item.value == widget.value) {
        return item.label;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final selectedText = _getSelectedText();

    return FTile(
      key: _key,
      title: Text(
        widget.title,
        style: TextStyle(
          color: widget.color ?? Colors.black,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null) ...[
            Text(
              widget.subtitle!,
              maxLines: 999,
              style: TextStyle(
                color: (widget.color ?? Colors.black).withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
            SizedBox(height: 4),
          ],
          // 当前选择显示在副标题下方
          Text(
            '当前选择：$selectedText',
            style: TextStyle(
              color: (widget.color ?? Colors.black).withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
      prefixIcon: Container(
        // padding: EdgeInsets.all(8),
        // decoration: BoxDecoration(
        //   color: MTheme.primary2.withValues(alpha: 0.1),
        //   borderRadius: BorderRadius.circular(8),
        // ),
        child: SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: FaIcon(
              widget.icon,
              color: widget.color ?? Colors.black,
              size: 14,
            ),
          ),
        ),
      ),
      suffixIcon: AnimatedRotation(
        turns: _isOpen ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
        child: FIcon(
          FAssets.icons.chevronDown,
          size: 14,
          color: Colors.grey,
        ),
      ),
      onPress: _toggleDropdown,
      style: context.theme.tileGroupStyle.tileStyle.copyWith(
        border: Border.all(color: Colors.transparent, width: 0),
      ),
    );
  }
}

class SimpleDropdownItem<T> {
  final String label;
  final T value;
  final Widget? icon;
  final bool enabled;

  const SimpleDropdownItem({
    required this.label,
    required this.value,
    this.icon,
    this.enabled = true,
  });
}
