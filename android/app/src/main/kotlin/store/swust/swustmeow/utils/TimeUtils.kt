package store.swust.swustmeow.utils

import java.time.Duration
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Calendar
import java.util.Date

object TimeUtils {
    fun getCurrentMD(): String {
        val currentDate = LocalDate.now()
        val formatter = DateTimeFormatter.ofPattern("MM/dd")
        return currentDate.format(formatter)
    }

    fun getCurrentYMD(): String {
        val currentDate = LocalDate.now()
        val formatter = DateTimeFormatter.ofPattern("yyyy/MM/dd")
        return currentDate.format(formatter)
    }

    private fun getWeekday(): Int {
        val weekday = LocalDate.now().dayOfWeek
        return weekday.value
    }

    fun getWeekdayDisplayString(): String {
        val w = arrayOf("周一", "周二", "周三", "周四", "周五", "周六", "周日")
        return w[getWeekday() - 1]
    }
}

fun Int.padL2(): String = toString().padStart(2, '0')

fun Date.add(duration: Duration): Date = Date(this.time + duration.toMillis())

fun Date.month(): Int {
    val calendar = Calendar.getInstance()
    calendar.time = this
    return calendar.get(Calendar.MONTH) + 1
}

fun Date.day(): Int {
    val calendar = Calendar.getInstance()
    calendar.time = this
    return calendar.get(Calendar.DAY_OF_MONTH)
}

fun Date.monthDayEquals(date: Date): Boolean {
    return this.month() == date.month() && this.day() == date.day()
}

