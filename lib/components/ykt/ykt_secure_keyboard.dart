import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:convert';

class YKTSecureKeyboard extends StatefulWidget {
  final String keyboard; // 键盘映射字符串，例如 '<7_2[T~pB' 或 '518627903'（纯数字情况）
  final List<String>? images; // 每个按钮对应的图片base64，可为空
  final Function(String) onPasswordComplete; // 密码输入完成的回调
  final int maxLength; // 最大密码长度
  final Function() onCancel; // 关闭键盘回调

  const YKTSecureKeyboard({
    super.key,
    required this.keyboard,
    this.images,
    required this.onPasswordComplete,
    required this.onCancel,
    this.maxLength = 6,
  });

  @override
  State<YKTSecureKeyboard> createState() => _YKTSecureKeyboardState();
}

class _YKTSecureKeyboardState extends State<YKTSecureKeyboard> {
  final List<int> _indices = []; // 存储用户点击的按钮索引
  late List<Uint8List>? _decodedImages; // 存储解码后的图片数据
  late bool _useImages;

  @override
  void initState() {
    super.initState();
    // 在初始化时预先解码所有图片（如果有）
    _decodedImages = widget.images?.map((img) => base64Decode(img)).toList();
    _useImages = _decodedImages != null && _decodedImages!.isNotEmpty;
  }

  String get _currentPassword {
    return _useImages
        ? _indices.map((index) => widget.keyboard[index]).join()
        : _indices.map((index) => index.toString()).join();
  }

  void _onKeyPressed(int index) {
    if (_indices.length < widget.maxLength) {
      setState(() {
        _indices.add(index);
      });

      // 如果达到最大长度，自动完成
      if (_indices.length == widget.maxLength) {
        widget.onPasswordComplete(_currentPassword);
      }
    }
  }

  void _onBackspace() {
    if (_indices.isNotEmpty) {
      setState(() {
        _indices.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 安全键盘标题
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    '安全键盘',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // 添加"请输入一卡通密码"提示
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '请输入一卡通密码',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),

            // 密码输入显示区域
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.maxLength,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _indices.length
                          ? Colors.black
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 键盘区域
            Column(
              children: [
                // 前三行，每行3个数字按钮
                for (int row = 0; row < 3; row++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (int col = 0; col < 3; col++)
                          _buildKeyButton(row * 3 + col),
                      ],
                    ),
                  ),

                // 最后一行，包含关闭和退格按钮
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 关闭键盘按钮
                      _buildSpecialButton(
                        icon: Icons.close,
                        onTap: widget.onCancel,
                      ),
                      // 数字9按钮
                      _buildKeyButton(9),
                      // 退格按钮
                      _buildSpecialButton(
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyButton(int index) {
    // 如果是图片模式且索引超出范围
    if (_useImages && index >= _decodedImages!.length) {
      return SizedBox(width: 60, height: 60);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPressed(index),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: _useImages
                ? Image.memory(
                    _decodedImages![index],
                    width: 30,
                    height: 30,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, color: Colors.red);
                    },
                  )
                : Text(
                    widget.keyboard[index],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Icon(icon, size: 20, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
