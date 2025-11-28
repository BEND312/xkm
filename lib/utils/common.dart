import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:swustmeow/data/values.dart';
import 'package:swustmeow/services/box_service.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/services/value_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

Future<void> clearCaches() async {
  // 清除缓存
  await Values.cache.emptyCache();
  ValueService.clearCache();

  // 清除所有 Box
  await BoxService.clearCache();
  await BoxService.open();

  // 重载 `GlobalService`
  await GlobalService.load();
}

void showToast({
  required Color color,
  required Color textColor,
  required String message,
  Alignment? alignment = Alignment.bottomCenter,
  int seconds = 3,
}) {
  BotToast.showText(
    text: message,
    contentColor: color.withValues(alpha: 0.8),
    textStyle: TextStyle(color: textColor),
    align: Alignment(0, 0.82),
    duration: Duration(seconds: seconds),
    onlyOne: true,
    enableKeyboardSafeArea: true,
    crossPage: true,
  );
}

void showInfoToast(
  String message, {
  Alignment? alignment,
  int seconds = 3,
}) =>
    showToast(
      color: Colors.white,
      textColor: Colors.black,
      message: message,
      alignment: alignment,
      seconds: seconds,
    );

void showSuccessToast(
  String message, {
  Alignment? alignment,
  int seconds = 3,
}) =>
    showToast(
      color: Colors.green,
      textColor: Colors.white,
      message: message,
      alignment: alignment,
      seconds: seconds,
    );

void showWarningToast(
  BuildContext context,
  String message, {
  Alignment? alignment,
  int seconds = 3,
}) =>
    showToast(
      color: Colors.orange,
      textColor: Colors.white,
      message: message,
      alignment: alignment,
      seconds: seconds,
    );

void showErrorToast(
  String message, {
  Alignment? alignment,
  int seconds = 3,
}) =>
    showToast(
      color: Colors.red,
      textColor: Colors.white,
      message: message,
      alignment: alignment,
      seconds: seconds,
    );

Future<bool> launchLink(String link) async {
  final uri = Uri.parse(link);
  if (await canLaunchUrl(uri)) {
    final result = await launchUrlString(
      link,
      mode: uri.scheme.startsWith('http')
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault,
    );
    return result;
  } else {
    return false;
  }
}
