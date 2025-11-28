import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class SimpleTabs extends StatefulWidget {
  const SimpleTabs(
      {super.key,
      required this.count,
      required this.titleBuilder,
      required this.contentBuilder,
      this.initialPage = 0})
      : assert(count > 0, '必须要有至少一个页面'),
        assert(initialPage < count, '初始页面索引不得大于总页面数');

  final int count;
  final Widget Function(BuildContext context, int index, bool isActive)
      titleBuilder;
  final Widget Function(BuildContext context, int index) contentBuilder;
  final int initialPage;

  @override
  State<StatefulWidget> createState() => _SimpleTabsState();
}

class _SimpleTabsState extends State<SimpleTabs> {
  late int _index;
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _index = widget.initialPage;
    _controller = PageController(initialPage: _index)
      ..addListener(() {
        var page = _controller.positions.isEmpty || _controller.page == null
            ? 0
            : _controller.page ?? 0;
        page = page > 0 ? page : 0;
        final diff = (page - page.toInt()).abs().toDouble();
        final result = diff >= 0.5 ? page.ceil() : page.floor();
        _refresh(() => _index = result);
      });
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  Widget _buildTab(int index) {
    final c = context.theme.colorScheme;
    final active = _index == index;

    return FTappable(
        onPress: () {
          _controller.animateToPage(index,
              duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
        },
        child: Container(
          decoration: BoxDecoration(
              color: active ? c.primary : c.secondary,
              border: Border.all(width: 1.0, color: c.border),
              borderRadius: BorderRadius.all(Radius.circular(16.0))),
          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          child: Center(child: widget.titleBuilder(context, index, active)),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.count,
            itemBuilder: (context, index) => _buildTab(index),
            separatorBuilder: (context, index) => SizedBox(width: 8.0),
          ),
        ),
        SizedBox(height: 16.0),
        PageView.builder(
          controller: _controller,
          itemCount: widget.count,
          itemBuilder: (context, index) =>
              widget.contentBuilder(context, index),
        )
      ],
    );
  }
}
