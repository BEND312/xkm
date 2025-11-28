import 'package:json_annotation/json_annotation.dart';

part 'chaoxing_homework.g.dart';

@JsonSerializable()
class ChaoXingHomework {
  final String title;
  final List<String> labels;
  final String status;

  const ChaoXingHomework({
    required this.title,
    required this.labels,
    required this.status,
  });

  factory ChaoXingHomework.fromJson(Map<String, dynamic> json) =>
      _$ChaoXingHomeworkFromJson(json);

  @override
  String toString() {
    return 'ChaoXingHomework(title: $title, labels: $labels, status: $status)';
  }
}
