import 'dart:math';
import 'package:flutter/material.dart';

// 卡片正面花纹绘制器
class YKTCardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 绘制一些随机的曲线作为卡片纹理
    for (int i = 0; i < 15; i++) {
      final path = Path();
      path.moveTo(0, size.height * (0.2 + 0.05 * i));

      for (int j = 0; j <= 4; j++) {
        final x = size.width * (j / 4);
        final y = size.height * (0.2 + 0.05 * i) +
            (j % 2 == 0 ? -10 : 10) * sin(i * 0.5);

        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 卡片背面花纹绘制器
class YKTCardBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 绘制背面纹理
    for (int i = 0; i < 20; i++) {
      final path = Path();
      path.moveTo(size.width * 0.1, size.height * (0.05 * i));
      path.lineTo(size.width * 0.9, size.height * (0.05 * i));
      canvas.drawPath(path, paint);
    }

    for (int i = 0; i < 20; i++) {
      final path = Path();
      path.moveTo(size.width * (0.05 * i), size.height * 0.1);
      path.lineTo(size.width * (0.05 * i), size.height * 0.9);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
