import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:swustmeow/data/values.dart';
import 'package:swustmeow/entity/activity_type.dart';
import 'package:swustmeow/services/boxes/activities_box.dart';
import 'package:swustmeow/utils/status.dart';

import '../entity/activity.dart';
import '../utils/time.dart';

final today = [
  Activity(
    name: '今天',
    type: ActivityType.today,
    dateString: DateTime.now().dateString,
    holiday: false,
  )
];

final festivals = [
  // 跨年前夕：12.31
  Activity.hidden(dateString: '12.31', greetings: ['一起迎接新年吧🌟', '跨年倒计时🥳']),

  // 元旦：01.01
  Activity.festival(
    name: '元旦',
    dateString: '01.01',
    greetingsGetter: (DateTime date) => [
      '${date.year + 1}，你好🥳',
      '新的一年🎉',
      'Happy New Year🎉',
      '元旦快乐🥳',
      '庆祝地球公转一周🎉',
      '愿新年带来新希望✨',
      '新的起点 新的梦想🌟'
    ],
  ),

  // 除夕：正月初一前一天
  Activity.festival(
    name: '除夕',
    dateStringGetter: (DateTime date) =>
        lunarToSolar(date.year, 1, 1).nextDay(-1).dateString,
    greetings: ['新年的钟声即将敲响🎉', '新年倒计时🥳'],
  ),

  // 春节：正月初一到正月初七
  Activity.festival(
    name: '春节',
    dateStringGetter: (DateTime date) =>
        getLunarDurationDateString(date.year, 1, 1, 7),
    greetings: [
      'Happy New Year🎉',
      '新年快乐🎉',
      '一起看烟花吧🎆',
      '新年快乐 红包拿来🧧',
      '炮竹声中一岁除🧨',
      '新春大吉 幸福安康🎉',
      '阖家欢乐 平安喜乐🏠',
      '红红火火过大年🔥'
    ],
  ),

  // 元宵节：正月十五
  Activity.festival(
    name: '元宵节',
    dateStringGetter: (DateTime date) => lunarToDateString(date.year, 1, 15),
    greetings: ['元宵节快乐🥳', '猜灯谜 吃汤圆🤪', '灯笼照亮夜空🏮', '汤圆甜在心里🥰'],
  ),

  // 妇女节：03.08
  Activity.festival(
    name: '妇女节',
    holiday: false,
    dateString: '03.08',
    greetings: ['女神们节日快乐👑'],
  ),

  // 愚人节：04.01
  Activity.festival(
    name: '愚人节',
    holiday: false,
    dateString: '04.01',
    greetings: ['今天你被骗了吗😆'],
  ),

  // 清明节：清明节气当天，持续3天
  Activity.festival(
    name: '清明节',
    dateStringGetter: (DateTime date) =>
        getSolarDurationDateString(getJieQi(date, '清明'), 3) ?? '04.04-04.06',
    greetings: ['缅怀先人🕯️', '思念故人 心中缅怀🕯️', '清明时节雨纷纷🌧️'],
  ),

  // 劳动节：05.01-05.05
  Activity.festival(
    name: '劳动节',
    dateString: '05.01-05.05',
    greetings: ['劳动节快乐🥳', '劳动最光荣💪'],
  ),

  // 青年节：05.04
  Activity.festival(name: '青年节', dateString: '05.04'),

  // 端午节：五月初五，持续3天
  Activity.festival(
    name: '端午节',
    dateStringGetter: (DateTime date) =>
        getLunarDurationDateString(date.year, 5, 5 - 2, 3),
    greetings: ['端午节安康🐲', '吃粽子 赛龙舟🐲'],
  ),

  // 国庆前夕：10.01前一天
  Activity.hidden(
    dateStringGetter: (DateTime date) =>
        DateTime(date.year, 10, 1).yesterday.dateString,
    greetings: ['国庆倒计时🥳', '国庆狂欢倒计时🎉', '准备好迎接国庆了吗🥳'],
  ),

  // 国庆节：10.01，持续7天
  Activity.festival(
    name: '国庆节',
    dateString: '10.01-10.07',
    greetings: ['举国同庆🎉', '祖国母亲生日快乐🥳', '国旗飘扬心中🇨🇳', '愿祖国繁荣昌盛🌟'],
  ),

  // 中秋节：八月十五，向前放假三天
  Activity.festival(
    name: '中秋节',
    holiday: true,
    dateStringGetter: (DateTime date) {
      final d = dateStringToDate(lunarToDateString(date.year, 8, 15));
      return '${d.subtract(const Duration(days: 2)).dateString}-${d.dateString}';
    },
    greetings: ['中秋节快乐🥳', '月圆人团圆✨', '赏月吃月饼🥮'],
  ),

  // 万圣节：11.01
  Activity.festival(
    name: '万圣节',
    holiday: false,
    dateString: '11.01',
    greetings: ['Happy Halloween🎃', '不给糖就捣蛋👻🍬', '万圣节快乐👻😈'],
  ),

  // 圣诞节：12.25
  Activity.festival(
    name: '圣诞节',
    holiday: false,
    dateString: '12.25',
    greetings: ['Merry Christmas🎄', '圣诞节快乐🎄', '圣诞老人带着礼物来啦🎁'],
  ),
];

final defaultActivities = today + festivals;

Future<StatusContainer<List<Activity>>> getExtraActivities(
    {bool force = false}) async {
  final cache = ActivitiesBox.get('extraActivities') as List<dynamic>?;
  final lastCheck = ActivitiesBox.get('extraActivitiesLastCheck') as DateTime?;
  if (force ||
      cache == null ||
      lastCheck == null ||
      lastCheck.isYMDBefore(DateTime.now())) {
    final r = await fetchExtraActivities();
    if (r.status != Status.ok || r.value == null || r.value?.isEmpty == true) {
      return const StatusContainer(Status.fail);
    }

    return r;
  }

  return StatusContainer(Status.ok, cache.cast());
}

Future<StatusContainer<List<Activity>>> fetchExtraActivities() async {
  final dio = Dio();

  try {
    // 直接使用硬编码的 URL
    final resp = await dio.get(Values.activitiesUrl);
    final r = resp.data;
    if (r is! Map) {
      return const StatusContainer(Status.fail);
    }

    // TODO 优化这里的逻辑 优化数据结构
    getCommonOrBigHoliday(String key) {
      List<Map<String, dynamic>> lm = ((r[key] ?? []) as List<dynamic>).cast();
      return lm.map((m) {
        final name = m['name'] as String;
        final dateString = m['dateString'] as String;
        List<String>? greetings = (m['greetings'] as List<dynamic>?)?.cast();
        return key == 'common'
            ? Activity.common(
                name: name, dateString: dateString, greetings: greetings)
            : Activity.bigHoliday(
                name: name, dateString: dateString, greetings: greetings);
      }).toList();
    }

    final common = getCommonOrBigHoliday('common');
    final bigHoliday = getCommonOrBigHoliday('bigHoliday');
    final shift = ((r['shift'] ?? []) as List<dynamic>)
        .cast()
        .map((ds) => Activity.shift(dateString: ds))
        .toList();

    final result = common + bigHoliday + shift;
    await ActivitiesBox.put('extraActivities', result);
    await ActivitiesBox.put('extraActivitiesLastCheck', DateTime.now());

    return StatusContainer(Status.ok, result);
  } on Exception catch (e, st) {
    debugPrint(e.toString());
    debugPrintStack(stackTrace: st);
    return const StatusContainer(Status.fail);
  }
}
