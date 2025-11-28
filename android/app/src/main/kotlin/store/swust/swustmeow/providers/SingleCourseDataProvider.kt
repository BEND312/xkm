package store.swust.swustmeow.providers

import store.swust.swustmeow.entities.SingleCourse

data class SingleCourseDataProvider(
    val date: String,
    val weekday: String,
    val weekNum: Int,
    val currentCourse: SingleCourse?,
    val nextCourse: SingleCourse?,
)