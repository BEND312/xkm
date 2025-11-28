import 'package:swustmeow/services/boxes/apartment_box.dart';
import 'package:swustmeow/services/boxes/calendar_box.dart';
import 'package:swustmeow/services/boxes/chaoxing_box.dart';
import 'package:swustmeow/services/boxes/common_box.dart';
import 'package:swustmeow/services/boxes/duifene_box.dart';
import 'package:swustmeow/services/boxes/soa_box.dart';
import 'package:swustmeow/services/boxes/ykt_box.dart';

import 'boxes/activities_box.dart';
import 'boxes/course_box.dart';
import 'boxes/webview_cookie_box.dart';

class BoxService {
  static Future<void> open() async {
    await ActivitiesBox.open();
    await CalendarBox.open();
    await CourseBox.open();
    await CommonBox.open();
    await SOABox.open();
    await DuiFenEBox.open();
    await ApartmentBox.open();
    await YKTBox.open();
    await ChaoXingBox.open();
    await WebViewCookieBox.open();
  }

  static Future<void> clearCache() async {
    await ActivitiesBox.clearCache();
    await CalendarBox.clearCache();
    await CourseBox.clearCache();
    await CommonBox.clearCache();
    await SOABox.clearCache();
    await DuiFenEBox.clearCache();
    await ApartmentBox.clearCache();
    await YKTBox.clearCache();
    await ChaoXingBox.clearCache();
    await WebViewCookieBox.clearCache();
  }
}
