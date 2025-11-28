import 'package:hive/hive.dart';

part 'score_type.g.dart';

@HiveType(typeId: 23)
enum ScoreType {
  @HiveField(0)
  plan,
  @HiveField(1)
  common,
  @HiveField(2)
  physical;
}

class ScoreTypeData {
  final String name;

  const ScoreTypeData(this.name);

  factory ScoreTypeData.of(ScoreType type) => switch (type) {
        ScoreType.plan => ScoreTypeData('计划课程'),
        ScoreType.common => ScoreTypeData('全校通选课'),
        ScoreType.physical => ScoreTypeData('体育项目')
      };
}
