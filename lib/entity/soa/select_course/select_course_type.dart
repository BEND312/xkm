enum SelectCourseType {
  programTask,
  commonTask,
  sportTask,
  // retakeTask,
  // fixupTask;
}

class SelectCourseTypeData {
  final String name;
  final String tableName;

  const SelectCourseTypeData(this.name, this.tableName);

  factory SelectCourseTypeData.of(SelectCourseType type) => switch (type) {
        SelectCourseType.programTask =>
          SelectCourseTypeData('计划课程', 'PlanTask'),
        SelectCourseType.commonTask =>
          SelectCourseTypeData('全校通选课', 'CommonTask'),
        SelectCourseType.sportTask => SelectCourseTypeData('体育项目', 'SportTask'),
        // SelectCourseType.retakeTask => SelectCourseTypeData('重新学习'),
        // SelectCourseType.fixupTask => SelectCourseTypeData('补选低年级课程'),
      };
}
