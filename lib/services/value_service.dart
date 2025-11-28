import 'package:flutter/cupertino.dart';
import 'package:swustmeow/entity/activity.dart';

import '../entity/soa/course/course_entry.dart';
import '../entity/soa/course/courses_container.dart';

class ValueService {
  static ValueNotifier<bool> isCourseLoading = ValueNotifier(false);
  static bool cacheSuccess = false;
  static List<Activity> activities = [];
  static List<CoursesContainer> coursesContainers = [];
  static ValueNotifier<CoursesContainer?> currentCoursesContainer = ValueNotifier(null);
  static List<CourseEntry> todayCourses = [];
  static CourseEntry? nextCourse;
  static CourseEntry? currentCourse;
  static Map<String, List<dynamic>> customCourses = {};

  static String? currentGreeting;

  static ValueNotifier<double?> homeHeaderCourseCarouselCardHeight =
      ValueNotifier(null);

  static ValueNotifier<bool> isReviewMode = ValueNotifier(false);

  static ValueNotifier<String> currentPath = ValueNotifier('/');

  static void clearCache() {
    activities = [];
    coursesContainers = [];
    currentCoursesContainer.value = null;
    todayCourses = [];
    nextCourse = null;
    currentCourse = null;
  }
}
