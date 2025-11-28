package store.swust.swustmeow.providers

import store.swust.swustmeow.entities.SimpleCourseEntry
import java.util.Date

data class CourseTableDataProvider(
    val weekNum: Int,
    val termStartDate: Date,
    val entries: List<SimpleCourseEntry>,
    val courseTableTimes: List<String>,
    val term: String
)