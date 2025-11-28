import 'package:json_annotation/json_annotation.dart';

part 'chaoxing_exam.g.dart';

@JsonSerializable()
class ChaoXingExam {
  final String title;
  final String status;

  const ChaoXingExam({required this.title, required this.status});

  factory ChaoXingExam.fromJson(Map<String, dynamic> json) =>
      _$ChaoXingExamFromJson(json);

  @override
  String toString() {
    return 'ChaoXingExam(title: $title, status: $status)';
  }
}
