import 'package:flutter/material.dart';
import 'package:swustmeow/services/account/account_service.dart';

class Tool {
  final String id; // 唯一标识符
  final String name; // 工具名称
  final String path; // 路由路径
  final Widget icon; // 图标
  final ValueNotifier<Color> color; // 颜色
  final Widget Function() pageBuilder; // 页面构建器
  final AccountService? Function()? serviceGetter; // 服务获取器
  final Future<void> Function(BuildContext)? onTap; // 自定义点击回调
  bool isVisible; // 是否在首页显示
  int order; // 用户自定义排序

  Tool({
    required this.id,
    required this.name,
    required this.path,
    required this.icon,
    required this.color,
    required this.pageBuilder,
    this.serviceGetter,
    this.onTap,
    this.isVisible = true,
    required this.order,
  });

  // 从JSON构造方法
  factory Tool.fromJson(Map<String, dynamic> json, List<Tool> defaultTools) {
    // 查找默认工具以获取不能序列化的属性
    final defaultTool = defaultTools.firstWhere((t) => t.id == json['id']);

    return Tool(
      id: json['id'],
      name: defaultTool.name,
      path: json['path'] ?? defaultTool.path,
      icon: defaultTool.icon,
      color: defaultTool.color,
      pageBuilder: defaultTool.pageBuilder,
      serviceGetter: defaultTool.serviceGetter,
      onTap: defaultTool.onTap,
      isVisible: json['isVisible'] ?? true,
      order: json['order'] ?? defaultTool.order,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'isVisible': isVisible,
      'order': order,
    };
  }

  // 创建副本
  Tool copyWith({
    String? name,
    String? path,
    Widget? icon,
    ValueNotifier<Color>? color,
    Widget Function()? pageBuilder,
    AccountService Function()? serviceGetter,
    Future<void> Function(BuildContext)? onTap,
    bool? isVisible,
    int? order,
  }) {
    return Tool(
      id: id,
      name: name ?? this.name,
      path: path ?? this.path,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      pageBuilder: pageBuilder ?? this.pageBuilder,
      serviceGetter: serviceGetter ?? this.serviceGetter,
      onTap: onTap ?? this.onTap,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  @override
  String toString() {
    return '''Tool(
      id: $id,
      name: $name,
      path: $path,
      icon: $icon,
      color: ${color.value},
      isVisible: $isVisible,
      order: $order,
    )''';
  }
}
