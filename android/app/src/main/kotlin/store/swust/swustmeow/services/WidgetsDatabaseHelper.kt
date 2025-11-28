package store.swust.swustmeow.services

import android.annotation.SuppressLint
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log
import store.swust.swustmeow.entities.WidgetsData

class WidgetsDatabaseHelper(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "widgets.db"
        private const val DATABASE_VERSION = 1
        private const val TABLE_NAME = "widgets"
    }

    private lateinit var db: SQLiteDatabase

    override fun onCreate(db: SQLiteDatabase?) {}

    override fun onUpgrade(db: SQLiteDatabase?, oldVersion: Int, newVersion: Int) {}

    private fun open() {
        db = readableDatabase
    }

    override fun close() {
        if (db.isOpen) {
            db.close()
        }
    }

    @SuppressLint("Recycle")
    fun query(): WidgetsData? {
        try {
            open()
            val cursor = db.query(
                TABLE_NAME,
                null,
                null,
                null,
                null,
                null,
                null,
                "1"
            )

            if (cursor != null && cursor.moveToFirst()) {
                val singleCourseSuccessIndex = cursor.getColumnIndex("single_course_success")
                val singleCourseLastUpdateTimestampIndex =
                    cursor.getColumnIndex("single_course_last_update_timestamp")
                val singleCourseCurrentCourseJsonIndex =
                    cursor.getColumnIndex("single_course_current_course_json")
                val singleCourseNextCourseJsonIndex =
                    cursor.getColumnIndex("single_course_next_course_json")
                val singleCourseWeekNumIndex = cursor.getColumnIndex("single_course_week_num")
                val todayCoursesSuccessIndex = cursor.getColumnIndex("today_courses_success")
                val todayCoursesLastUpdateTimestampIndex =
                    cursor.getColumnIndex("today_courses_last_update_timestamp")
                val todayCoursesTodayCoursesListIndex =
                    cursor.getColumnIndex("today_courses_today_courses_list")
                val todayCoursesWeekNumIndex = cursor.getColumnIndex("today_courses_week_num")
                val courseTableSuccessIndex = cursor.getColumnIndex("course_table_success")
                val courseTableLastUpdateTimestampIndex =
                    cursor.getColumnIndex("course_table_last_update_timestamp")
                val courseTableEntriesJsonIndex =
                    cursor.getColumnIndex("course_table_entries_json")
                val courseTableWeekNumIndex = cursor.getColumnIndex("course_table_week_num")
                val courseTableTermStartDateIndex =
                    cursor.getColumnIndex("course_table_term_start_date")
                val courseTableTimesJsonIndex = cursor.getColumnIndex("course_table_times_json")
                val courseTableTermIndex = cursor.getColumnIndex("course_table_term")

                if (
                    singleCourseSuccessIndex != -1 &&
                    singleCourseLastUpdateTimestampIndex != -1 &&
                    singleCourseWeekNumIndex != -1 &&
                    todayCoursesSuccessIndex != -1 &&
                    todayCoursesLastUpdateTimestampIndex != -1 &&
                    todayCoursesWeekNumIndex != -1
                ) {
                    val data = WidgetsData(
                        singleCourseSuccess = cursor.getInt(singleCourseSuccessIndex),
                        singleCourseLastUpdateTimestamp = cursor.getLong(
                            singleCourseLastUpdateTimestampIndex
                        ),
                        singleCourseCurrentCourseJson = if (singleCourseCurrentCourseJsonIndex != -1) cursor.getString(
                            singleCourseCurrentCourseJsonIndex
                        ) else null,
                        singleCourseNextCourseJson = if (singleCourseNextCourseJsonIndex != -1) cursor.getString(
                            singleCourseNextCourseJsonIndex
                        ) else null,
                        singleCourseWeekNum = cursor.getInt(singleCourseWeekNumIndex),
                        todayCoursesSuccess = cursor.getInt(todayCoursesSuccessIndex),
                        todayCoursesLastUpdateTimestamp = cursor.getLong(
                            todayCoursesLastUpdateTimestampIndex
                        ),
                        todayCoursesTodayCoursesList = if (todayCoursesTodayCoursesListIndex != -1) cursor.getString(
                            todayCoursesTodayCoursesListIndex
                        ) else null,
                        todayCoursesWeekNum = cursor.getInt(todayCoursesWeekNumIndex),
                        courseTableSuccess = cursor.getInt(courseTableSuccessIndex),
                        courseTableLastUpdateTimestamp = cursor.getLong(
                            courseTableLastUpdateTimestampIndex
                        ),
                        courseTableEntriesJson = if (courseTableEntriesJsonIndex != -1) cursor.getString(
                            courseTableEntriesJsonIndex
                        ) else null,
                        courseTableWeekNum = cursor.getInt(courseTableWeekNumIndex),
                        courseTableTermStartDate = if (courseTableTermStartDateIndex != -1) cursor.getString(
                            courseTableTermStartDateIndex
                        ) else null,
                        courseTableTimesJson = if (courseTableTimesJsonIndex != -1) cursor.getString(
                            courseTableTimesJsonIndex
                        ) else null,
                        courseTableTerm = if (courseTableTermIndex != -1) cursor.getString(
                            courseTableTermIndex
                        ) else null
                    )
                    cursor.close()
                    return data
                }
            }
            cursor?.close()
            return null
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        } finally {
            close()
        }
    }
}