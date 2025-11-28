import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:swustmeow/utils/courses.dart';

import '../../data/m_theme.dart';
import '../../entity/soa/course/course_entry.dart';

class HorizontalCourseCard extends StatelessWidget {
  const HorizontalCourseCard({
    super.key,
    // required this.height,
    required this.course,
    required this.isActive,
    required this.isNext,
  });

  // final double height;
  final CourseEntry course;
  final bool isActive;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final secondaryStyle = TextStyle(color: Colors.grey, fontSize: 14);
    final (time, diff) = getCourseRemainingString(course);

    return Container(
      height: 120,
      width: double.infinity,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course.courseName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              Text(
                isActive
                    ? '正在上课'
                    : isNext
                        ? '下节课'
                        : '',
                style: TextStyle(
                  color: MTheme.primary2.withValues(
                    alpha: isActive || isNext ? 1 : 0,
                  ),
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      course.teacherName.join('、'),
                      style: secondaryStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AutoSizeText(
                      course.place,
                      style: secondaryStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (!isActive && isNext)
                    Text(
                      '$diff后上课',
                      style: TextStyle(color: MTheme.primary2, fontSize: 12),
                    ),
                  Text(
                    time,
                    style: TextStyle(color: MTheme.primary2, fontSize: 18),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
