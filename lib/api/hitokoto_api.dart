import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:swustmeow/entity/hitokoto.dart';
import 'package:swustmeow/utils/status.dart';

Future<StatusContainer<Hitokoto>> getHitokoto() async {
  try {
    final categories = [
      'd', // 文学
      'i', // 诗词
      'k' // 哲学
    ];
    final c = categories.map((c) => 'c=$c').join('&');
    final dio = Dio();
    final resp = await dio.get('https://v1.hitokoto.cn/?$c');
    final result = resp.data;

    if (result is! Map) return const StatusContainer(Status.fail);
    final Map<String, dynamic> json = result.cast();
    final hitokoto = Hitokoto.fromJson(json);
    return StatusContainer(Status.ok, hitokoto);
  } on Exception catch (e, st) {
    debugPrintStack(stackTrace: st);
    return StatusContainer(Status.fail);
  }
}
