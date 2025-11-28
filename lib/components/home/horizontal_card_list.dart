import 'package:flutter/material.dart';

class HorizontalCardList extends StatefulWidget {
  const HorizontalCardList(
      {super.key,
      this.controller,
      this.cardMaxHeight,
      this.cardMaxWidth,
      this.viewWidth,
      this.selectedIndex = 2.0,
      required this.children,
      required this.getStartPosition,
      required this.getCardSize});

  final PageController? controller;
  final double? cardMaxWidth;
  final double? cardMaxHeight;
  final double? viewWidth;
  final List<Widget> children;
  final double? selectedIndex;
  final double Function(double, double?, double, int, double) getStartPosition;
  final double Function(double?, int, double) getCardSize;

  @override
  State<StatefulWidget> createState() => _CardListWidgetState();
}

class _CardListWidgetState extends State<HorizontalCardList> {
  double? selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
    widget.controller!.addListener(() {
      _refresh(() {
        selectedIndex = widget.controller!.page;
      });
    });
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cardList = [];

    for (int i = 0; i < widget.children.length; i++) {
      double cardWidth =
          widget.getCardSize(widget.cardMaxWidth, i, selectedIndex!);
      double cardHeight = cardWidth;
      double start = widget.getStartPosition(cardWidth, widget.cardMaxWidth,
              widget.viewWidth!, i, selectedIndex!) -
          220;

      Widget card = Positioned.directional(
        textDirection: TextDirection.ltr,
        bottom: widget.cardMaxHeight! - cardHeight + 40,
        start: start,
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Center(child: widget.children[i]),
        ),
      );

      cardList.add(card);
    }

    return Stack(children: [
      SizedBox(
        height: widget.cardMaxHeight,
        child: Stack(
          children: cardList,
        ),
      ),
      Positioned.fill(
        child: PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.children.length,
          controller: widget.controller,
          itemBuilder: (context, index) {
            return Container();
          },
        ),
      )
    ]);
  }
}
