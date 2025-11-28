package store.swust.swustmeow.entities

data class SimpleCourseEntry(
    val name: String,
    val place: String,
    val color: Long,
    val weekday: Int,
    val startWeek: Int,
    val endWeek: Int,
    val numberOfDay: Int,
    val startSection: Int,
    val endSection: Int,
)
