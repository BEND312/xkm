package store.swust.swustmeow.widgets.course_table

import store.swust.swustmeow.entities.SimpleCourseEntry
import java.util.Date

data class CourseTableWidgetState(
    val success: Boolean = false,
    val lastUpdateTimestamp: Long = 0,
    val weekNum: Int = 0,
    val entries: List<SimpleCourseEntry>? = null,
    val termStartDate: Date = Date(),
    val courseTableTimes: List<String> = emptyList()
)