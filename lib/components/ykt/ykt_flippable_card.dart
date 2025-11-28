import 'dart:math';
import 'package:flutter/material.dart';
import 'package:swustmeow/components/ykt/ykt_card_pattern.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/entity/ykt/ykt_card_account_info.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class YKTFlippableCard extends StatefulWidget {
  final YKTCard card;
  final YKTCardAccountInfo? accountInfo;
  final VoidCallback? onTap;

  const YKTFlippableCard({
    super.key,
    required this.card,
    this.accountInfo,
    this.onTap,
  });

  @override
  State<YKTFlippableCard> createState() => _YKTFlippableCardState();
}

class _YKTFlippableCardState extends State<YKTFlippableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAnimating = false;
  bool _isBackVisible = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
          _isBackVisible = !_isBackVisible;
          _animationController.reset();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void flipCard() {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _animationController.forward();
    });

    // 如果提供了onTap回调，则调用它
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flipCard,
      child: AnimatedBuilder(
        animation: CurvedAnimation(
          parent: _animationController,
          curve: Curves.elasticOut,
        ),
        builder: (context, child) {
          final double rotation = _animationController.value * pi;
          final bool showBackSide =
              _isBackVisible ? rotation < pi / 2 : rotation > pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_isBackVisible ? pi + rotation : rotation),
            child: showBackSide
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardBack(),
                  )
                : _buildCardFront(),
          );
        },
      ),
    );
  }

  Widget _buildCardFront() {
    final color = widget.card.isLocked ? Colors.grey : Color(widget.card.color);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: CustomPaint(
                painter: YKTCardPatternPainter(),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.2,
              child: Icon(
                FontAwesomeIcons.creditCard,
                size: 120,
                color: Colors.white,
              ),
            ),
          ),
          if (widget.accountInfo != null)
            Positioned(
              top: 24,
              right: 24,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.accountInfo!.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 24,
            left: 24,
            child: Text(
              widget.card.cardName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 24),
              child: RichText(
                text: TextSpan(
                  text: '￥',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: widget.accountInfo?.balance ?? '???',
                      style: TextStyle(fontSize: 36),
                    )
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            child: Text(
              '有效期至: ${widget.card.expireDate}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    final color = widget.card.isLocked ? Colors.grey : Color(widget.card.color);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: YKTCardBackPatternPainter(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '持卡人',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.card.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '卡号',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.card.account.trim(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                if (widget.card.departmentName.isNotEmpty) SizedBox(height: 12),
                if (widget.card.departmentName.isNotEmpty)
                  Text(
                    widget.card.departmentName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.card.isLocked)
            Positioned(
              top: 16,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '已挂失',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                FontAwesomeIcons.qrcode,
                size: 24,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
