import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/utils/empty.dart';

class HeaderSelector<T> extends StatefulWidget {
  final dynamic initialValue;
  final void Function(dynamic value) onSelect;
  final int count;
  final Widget Function(BuildContext context, T value) titleBuilder;
  final T Function(BuildContext context, int index) tileValueBuilder;
  final Widget Function(BuildContext context, int index) tileTextBuilder;
  final bool enabled;
  final bool autoHide;
  final double width;
  final Widget? fallbackTitle;
  final Color? color;

  const HeaderSelector({
    super.key,
    required this.initialValue,
    required this.onSelect,
    required this.count,
    required this.titleBuilder,
    required this.tileValueBuilder,
    required this.tileTextBuilder,
    this.enabled = true,
    this.autoHide = true,
    this.width = 160.0,
    this.fallbackTitle,
    this.color,
  });

  @override
  State<StatefulWidget> createState() => _HeaderSelectorState<T>();
}

class _HeaderSelectorState<T> extends State<HeaderSelector<T>>
    with SingleTickerProviderStateMixin {
  T? _currentValue;
  late FPopoverController _popoverController;
  late FRadioSelectGroupController<T> _groupController;
  bool _isPopoverOpened = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _popoverController = FPopoverController(vsync: this);
    _popoverController.addListener(() {
      _refresh(() => _isPopoverOpened = !_isPopoverOpened);
    });
    _groupController = FRadioSelectGroupController<T>(value: _currentValue);
    _groupController.addListener(() async {
      T? value = _groupController.value.firstOrNull;
      _refresh(() => _currentValue = value as T);
      widget.onSelect((value as T)!);
    });
  }

  @override
  void dispose() {
    _popoverController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentValue != null
        ? widget.titleBuilder(context, _currentValue as T)
        : widget.fallbackTitle;
    return SizedBox(
      width: widget.width,
      child: FSelectMenuTile.builder(
        title: title ?? const Empty(),
        groupController: _groupController,
        divider: FTileDivider.full,
        count: widget.count,
        enabled: widget.enabled,
        autoHide: widget.autoHide,
        suffixIcon: FIcon(
          FAssets.icons.chevronsUpDown,
          color: widget.color ?? Colors.white,
        ),
        menuAnchor: Alignment.topCenter,
        tileAnchor: Alignment.bottomCenter,
        menuTileBuilder: (context, index) {
          Widget text = widget.tileTextBuilder(context, index);
          T value = widget.tileValueBuilder(context, index);
          return FSelectTile<T>(
            title: Transform.translate(
              offset: Offset(-16.0, 0.0),
              child: Center(
                child: text,
              ),
            ),
            value: value,
            style: context.theme.selectMenuTileStyle.tileStyle,
          );
        },
        style: context.theme.selectMenuTileStyle.copyWith(
          tileStyle: context.theme.selectMenuTileStyle.tileStyle.copyWith(
            enabledBackgroundColor: Colors.transparent,
            enabledHoveredBackgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            border: Border.all(color: Colors.transparent, width: 0.0),
          ),
        ),
      ),
    );
  }
}
