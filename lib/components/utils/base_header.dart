import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/data/m_theme.dart';

class BaseHeader extends StatefulWidget {
  const BaseHeader({
    super.key,
    required this.title,
    this.suffixIcons,
    this.showBackButton = true,
    this.color,
  });

  final dynamic title;
  final List<Widget>? suffixIcons;
  final bool showBackButton;
  final Color? color;

  @override
  State<StatefulWidget> createState() => _BaseHeaderState();
}

class _BaseHeaderState extends State<BaseHeader> {
  final _mainRowKey = GlobalKey();
  double? _mainRowHeight;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox =
          _mainRowKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        setState(() {
          _mainRowHeight = renderBox.size.height;
        });
      }
    });

    return Stack(
      children: [
        Row(
          key: _mainRowKey,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.showBackButton
                ? IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: FaIcon(
                      FontAwesomeIcons.angleLeft,
                      color: widget.color ?? MTheme.backgroundText,
                      size: 18,
                    ),
                  )
                : IgnorePointer(
                    child: IconButton(
                      onPressed: () {},
                      icon: SizedBox(),
                    ),
                  ),
            Spacer(),
            Expanded(
              flex: 5,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 4.0),
                  child: widget.title is Widget
                      ? widget.title
                      : Text(
                          widget.title.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            color: widget.color ?? MTheme.backgroundText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            Spacer(),
            Expanded(child: SizedBox())
          ],
        ),
        AnimatedOpacity(
          opacity: _mainRowHeight == null ? 0 : 1,
          duration: Duration.zero,
          child: SizedBox(
            height: _mainRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.suffixIcons ?? [],
            ),
          ),
        )
      ],
    );
  }
}
