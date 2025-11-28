/*
 * Copyright (c) 2025 BEND
 *
 * This file is a new addition to the project, created as part of secondary development.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:swustmeow/entity/soa/course/course_entry.dart';
import 'package:swustmeow/entity/soa/course/course_type.dart';
import 'package:swustmeow/entity/soa/course/courses_container.dart';
import 'package:swustmeow/entity/soa/exam/exam_schedule.dart';
import 'package:swustmeow/entity/soa/exam/exam_type.dart';
import 'package:swustmeow/services/global_service.dart';

class ExamConverter {
  static CoursesContainer? examsToCourseContainer({
    required List<ExamSchedule> exams,
    String? term,
    String? userId,
    List<ExamType>? includeTypes,
  }) {
    if (exams.isEmpty) return null;
    final filteredExams = includeTypes != null
        ? exams.where((e) => includeTypes.contains(e.type)).toList()
        : exams;

    if (filteredExams.isEmpty) return null;
    final inferredTerm = term ?? _inferTermFromExams(filteredExams);
    final entries = filteredExams.map((exam) => _examToCourseEntry(exam)).toList();
    final containerId = _generateContainerId(userId, inferredTerm, 'exams');

    return CoursesContainer(
      type: CourseType.normal,
      term: inferredTerm,
      entries: entries,
      id: containerId,
      remark: '从考试安排生成',
    );
  }
  static CourseEntry _examToCourseEntry(ExamSchedule exam) {
    final displayName = _getDisplayNameForExam(exam);
    final startSection = (2 * exam.numberOfDay) - 1;
    final endSection = 2 * exam.numberOfDay;

    return CourseEntry(
      courseName: exam.courseName,
      displayName: displayName,
      teacherName: ['座次：${exam.seatNo}'], 
      startWeek: exam.weekNum,
      endWeek: exam.weekNum, 
      place: '${exam.place} ${exam.classroom}',
      weekday: exam.weekday,
      numberOfDay: exam.numberOfDay,
      startSection: startSection,
      endSection: endSection,
      isCustom: false, 
      isExam: true, 
    );
  }

  static String _getDisplayNameForExam(ExamSchedule exam) {
    final typeStr = switch (exam.type) {
      ExamType.finalExam => '期末考试',
      ExamType.midExam => '期中考试',
      ExamType.resitExam => '补考',
    };
    return '[$typeStr] ${exam.courseName}';
  }

  static String _inferTermFromExams(List<ExamSchedule> exams) {
    if (exams.isEmpty) {
      return _getCurrentTerm();
    }

    final dates = exams.map((e) => e.date).toList()..sort();
    final firstExamDate = dates.first;
    final termDates = GlobalService.termDates.value;
    for (final entry in termDates.entries) {
      final (startDate, endDate, _) = entry.value.value;
      if (firstExamDate.isAfter(startDate) && firstExamDate.isBefore(endDate)) {
        return entry.key;
      }
    }
    return _getCurrentTerm();
  }
  static String _getCurrentTerm() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    //简单处理
    if (month >= 8) {
      return '$year-${year + 1}-上';
    } else {
      return '${year - 1}-$year-下';
    }
  }

  static String _generateContainerId(String? userId, String term, String suffix) {
    final baseString = '${userId ?? 'unknown'}_${term}_$suffix';
    return sha1.convert(utf8.encode(baseString)).toString();
  }

  static List<CoursesContainer> examsToMultipleContainers({
    required List<ExamSchedule> exams,
    String? term,
    String? userId,
  }) {
    if (exams.isEmpty) return [];

    final result = <CoursesContainer>[];
    final examsByType = <ExamType, List<ExamSchedule>>{};
    for (final exam in exams) {
      examsByType.putIfAbsent(exam.type, () => []).add(exam);
    }

    for (final entry in examsByType.entries) {
      final container = examsToCourseContainer(
        exams: entry.value,
        term: term,
        userId: userId,
        includeTypes: [entry.key],
      );
      if (container != null) {
        result.add(container);
      }
    }

    return result;
  }

  static CoursesContainer mergeExamsToContainer({
    required CoursesContainer container,
    required List<ExamSchedule> exams,
    bool filterByTerm = true,
  }) {
    if (exams.isEmpty) return container;
    final filteredExams = filterByTerm
        ? exams.where((e) => _isExamInTerm(e, container.term)).toList()
        : exams;

    if (filteredExams.isEmpty) return container;
    final examEntries = filteredExams.map((e) => _examToCourseEntry(e)).toList();
    final mergedEntries = [...container.entries, ...examEntries];

    return CoursesContainer(
      type: container.type,
      term: container.term,
      entries: mergedEntries,
      id: container.id,
      remark: container.remark,
    );
  }

  static bool _isExamInTerm(ExamSchedule exam, String term) {
    final termDates = GlobalService.termDates.value[term]?.value;
    if (termDates == null) return false;

    final (startDate, endDate, _) = termDates;
    return exam.date.isAfter(startDate) && exam.date.isBefore(endDate);
  }

  static CoursesContainer? createExamPreview({
    required List<ExamSchedule> exams,
    bool onlyActive = true,
  }) {
    final filteredExams = onlyActive
        ? exams.where((e) => e.isActive).toList()
        : exams;

    if (filteredExams.isEmpty) return null;

    return examsToCourseContainer(
      exams: filteredExams,
      term: _inferTermFromExams(filteredExams),
      userId: 'preview',
    );
  }

  static (int total, int active, int finished) getExamStatistics(
    List<ExamSchedule> exams,
  ) {
    final total = exams.length;
    final active = exams.where((e) => e.isActive).length;
    final finished = total - active;
    return (total, active, finished);
  }
}
