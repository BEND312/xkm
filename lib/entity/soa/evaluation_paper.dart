class EvaluationPaper {
  String college;
  String course;
  String teacher;
  String url;

  EvaluationPaper({
    required this.college,
    required this.course,
    required this.teacher,
    required this.url,
  });

  factory EvaluationPaper.fromJson(Map<String, dynamic> json) {
    return EvaluationPaper(
      college: json['college'],
      course: json['course'],
      teacher: json['teacher'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course': course,
      'teacher': teacher,
      'college': college,
      'url': url,
    };
  }

  @override
  String toString() {
    return "EvaluationPaper={college=$college, course=$course, teacher=$teacher, url=$url}";
  }
}
