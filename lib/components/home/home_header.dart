import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/components/home/course_carousel.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/entity/activity.dart';
import 'package:swustmeow/data/global_keys.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/utils/time.dart';
import 'package:swustmeow/utils/widget.dart';
import 'package:swustmeow/views/calendar_page.dart';

import '../../data/m_theme.dart';
import '../../entity/soa/course/course_entry.dart';
import '../../entity/soa/course/courses_container.dart';
import '../../utils/common.dart';
import '../../views/course_table/course_table_page.dart';
import '../greeting.dart';

class HomeHeader extends StatefulWidget {
  final List<Activity> activities;
  final List<CoursesContainer> containers;
  final CoursesContainer? currentCourseContainer;
  final List<CourseEntry> todayCourses;
  final CourseEntry? nextCourse;
  final CourseEntry? currentCourse;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const HomeHeader({
    super.key,
    required this.activities,
    required this.containers,
    required this.currentCourseContainer,
    required this.todayCourses,
    required this.nextCourse,
    required this.currentCourse,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<StatefulWidget> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconDimension = 22.0;
    final now = DateTime.now();
    const weeks = ['一', '二', '三', '四', '五', '六', '日'];

    return Stack(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: MTheme.primary2,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.5),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(24.0, 8.0, 8.0, 0.0),
                  child: ListView(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Greeting(activities: widget.activities),
                          ),
                          buildShowcaseWidget(
                            key: GlobalKeys.showcaseRefreshKey,
                            title: '刷新',
                            description: '加载失败了？刷新试试！',
                            child: RefreshIcon(
                              isRefreshing: _isRefreshing,
                              iconDimension: iconDimension,
                              onRefresh: () async {
                                if (_isRefreshing) return;
                                setState(() => _isRefreshing = true);
                                _refreshAnimationController.repeat();
                                await widget.onRefresh();
                                setState(() => _isRefreshing = false);
                                _refreshAnimationController.stop();
                              },
                            ),
                          ),
                          buildShowcaseWidget(
                            key: GlobalKeys.showcaseCourseTableKey,
                            title: '课程表',
                            description: '快速、方便地查看当前和选课的课程表。',
                            child: IconButton(
                              onPressed: () {
                                if (widget.currentCourseContainer == null) {
                                  showErrorToast('当前无课程表，请刷新后重试');
                                  return;
                                }
                                pushTo(
                                  context,
                                  '/course_table',
                                  CourseTablePage(
                                    containers: widget.containers,
                                    currentContainer:
                                        widget.currentCourseContainer!,
                                    activities: widget.activities,
                                    showBackButton: true,
                                  ),
                                  pushInto: true,
                                );
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.tableCells,
                                size: iconDimension,
                                color: MTheme.backgroundText,
                              ),
                            ),
                          ),
                          buildShowcaseWidget(
                            key: GlobalKeys.showcaseCalendarKey,
                            title: '校历',
                            description: '快速查看、编辑校历。',
                            child: IconButton(
                              onPressed: () {
                                pushTo(
                                  context,
                                  '/calendar',
                                  CalendarPage(
                                    activities: widget.activities,
                                  ),
                                  pushInto: true,
                                );
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.calendarDay,
                                size: iconDimension,
                                color: MTheme.backgroundText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${now.month.padL2}月${now.day.padL2}日 星期${weeks[now.weekday - 1]}',
                        style: TextStyle(
                          color: MTheme.backgroundText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                buildShowcaseWidget(
                  key: GlobalKeys.showcaseCourseCardsKey,
                  title: '课程卡片',
                  description: '今日课程，如果当前时间之后没有课程了，会显示为一个一言卡片。',
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: CourseCarousel(
                    activities: widget.activities,
                    containers: widget.containers,
                    currentCourseContainer: widget.currentCourseContainer,
                    todayCourses: widget.todayCourses,
                    nextCourse: widget.nextCourse,
                    currentCourse: widget.currentCourse,
                    isLoading: widget.isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
