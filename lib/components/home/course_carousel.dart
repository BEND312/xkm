import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:math' as math;

import '../../entity/activity.dart';
import '../../entity/soa/course/course_entry.dart';
import '../../entity/soa/course/courses_container.dart';
import '../../services/boxes/common_box.dart';
import '../../services/value_service.dart';
import '../../utils/router.dart';
import '../../views/course_table/course_table_page.dart';
import 'horizontal_course_card.dart';

class CourseCarousel extends StatefulWidget {
  const CourseCarousel({
    super.key,
    required this.activities,
    required this.containers,
    required this.currentCourseContainer,
    required this.todayCourses,
    required this.nextCourse,
    required this.currentCourse,
    required this.isLoading,
  });

  final List<Activity> activities;
  final List<CoursesContainer> containers;
  final CoursesContainer? currentCourseContainer;
  final List<CourseEntry> todayCourses;
  final CourseEntry? nextCourse;
  final CourseEntry? currentCourse;
  final bool isLoading;

  @override
  State<StatefulWidget> createState() => _CourseCarouselState();
}

class _CourseCarouselState extends State<CourseCarousel> {
  late PageController _pageController;
  double _currentPage = 0.0;
  final double _viewPortFraction = 0.7;
  final GlobalKey _cardKey = GlobalKey();
  static const bottomPadding = 16.0;
  static const maxYOffset = 15.0;
  static const cardSpacing = 0.0;
  Timer? _timer;
  String? _hitokoto;
  String? _hitokotoFrom;
  String? _hitokotoFromWho;
  static const fallbackHitokoto = '只要开始追赶，就已经走在胜利的路上。';
  static const fallbackHitokotoFromWho = '雷军';

  @override
  void initState() {
    super.initState();

    int initialPage = 0;
    if (!widget.isLoading && widget.todayCourses.isNotEmpty) {
      if (widget.currentCourse != null) {
        initialPage = widget.todayCourses.indexOf(widget.currentCourse!);
      } else if (widget.nextCourse != null) {
        initialPage = widget.todayCourses.indexOf(widget.nextCourse!);
      }
    }

    _pageController = PageController(
      viewportFraction: _viewPortFraction,
      initialPage: initialPage,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageController.addListener(() {
          if (mounted) {
            setState(() {
              _currentPage = _pageController.page ?? 0.0;
            });
          }
        });

        final RenderBox? renderBox =
            _cardKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          setState(() {
            ValueService.homeHeaderCourseCarouselCardHeight.value =
                renderBox.size.height;
          });
        }
      }
    });

    _hitokoto = (CommonBox.get('hitokoto') as String?) ?? fallbackHitokoto;
    _hitokotoFrom = CommonBox.get('hitokotoFrom') as String?;
    _hitokotoFromWho = (CommonBox.get('hitokotoFromWho') as String?) ??
        fallbackHitokotoFromWho;

    // 每五分钟更新一次卡片
    _timer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  Widget _buildPager(List<CourseEntry> entries, {required int page}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });

    return FTappable(
      onPress: () {
        pushTo(
          context,
          '/course_table',
          CourseTablePage(
            containers: widget.containers,
            currentContainer: widget.currentCourseContainer!,
            activities: widget.activities,
            showBackButton: true,
          ),
          pushInto: true,
        );
      },
      child: ExpandablePageView(
        padEnds: true,
        controller: _pageController,
        children: List.generate(entries.length, (index) {
          double diff = index - _currentPage;
          double yOffset = maxYOffset * math.cos(diff.abs() * math.pi / 2);
          double heightScale = 1.0 - (diff.abs() * 0.1).clamp(0.0, 0.15);

          Matrix4 transform = Matrix4.identity()
            ..translate(0.0, yOffset, 0.0)
            ..scale(heightScale);
          final entry = entries[index];

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: cardSpacing / 2,
            ),
            child: Transform(
              transform: transform,
              alignment: Alignment.center,
              child: HorizontalCourseCard(
                course: entry,
                isActive: widget.currentCourse == entry,
                isNext: widget.nextCourse == entry,
              ),
            ),
          );
        }),
      ),
    );
  }

  String _buildHitokoto() {
    if (_hitokoto == null) return '加载中...';

    final from = _hitokotoFrom != null && _hitokotoFrom?.isNotEmpty == true
        ? '《$_hitokotoFrom》'
        : _hitokotoFromWho ?? fallbackHitokotoFromWho;
    return '$_hitokoto——$from';
  }

  Widget _buildHitokotoPage() {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          height: ValueService.homeHeaderCourseCarouselCardHeight.value ?? 0,
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.penNib),
                  SizedBox(width: 4.0),
                  Text(
                    '一言',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )
                ],
              ),
              AutoSizeText(
                _buildHitokoto(),
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '接下来没有课啦，好好休息吧~',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  List<CourseEntry> _randomEntries(int length) {
    return List.generate(
      length,
      (_) => CourseEntry(
        courseName: 'A' * 8,
        teacherName: ['A' * 3],
        startWeek: 1,
        endWeek: 99,
        place: 'A' * 8,
        weekday: 1,
        numberOfDay: 1,
        displayName: 'A' * 5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayCoursesFinished =
        widget.currentCourse == null && widget.nextCourse == null;

    if (ValueService.homeHeaderCourseCarouselCardHeight.value == null ||
        ValueService.homeHeaderCourseCarouselCardHeight.value == 0) {
      return Opacity(
        opacity: 0,
        child: HorizontalCourseCard(
          key: _cardKey,
          course: _randomEntries(1).first,
          isActive: false,
          isNext: false,
        ),
      );
    }

    return SizedBox(
      height: (ValueService.homeHeaderCourseCarouselCardHeight.value ?? 0.0) +
          maxYOffset +
          bottomPadding,
      child: Skeletonizer(
        enabled: widget.isLoading,
        child: widget.isLoading
            ? _buildPager(_randomEntries(2), page: 0)
            : !todayCoursesFinished
                ? _buildPager(
                    widget.todayCourses,
                    page: widget.todayCourses.firstOrNull != null
                        ? widget.todayCourses.indexOf(
                            widget.currentCourse ??
                                widget.nextCourse ??
                                widget.todayCourses.first,
                          )
                        : 0,
                  )
                : _buildHitokotoPage(),
      ),
    );
  }
}
