package store.swust.swustmeow.entities

data class WidgetsData(
    val singleCourseSuccess: Int,
    val singleCourseLastUpdateTimestamp: Long,
    val singleCourseCurrentCourseJson: String?,
    val singleCourseNextCourseJson: String?,
    val singleCourseWeekNum: Int,
    val todayCoursesSuccess: Int,
    val todayCoursesLastUpdateTimestamp: Long,
    val todayCoursesTodayCoursesList: String?,
    val todayCoursesWeekNum: Int,
    val courseTableSuccess: Int,
    val courseTableLastUpdateTimestamp: Long,
    val courseTableEntriesJson: String?,
    val courseTableWeekNum: Int,
    val courseTableTermStartDate: String?,
    val courseTableTimesJson: String?,
    val courseTableTerm: String?
)