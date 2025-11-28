package store.swust.swustmeow.widgets.course_table

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import store.swust.swustmeow.components.CourseLoadErrorBox
import store.swust.swustmeow.components.course_table.CourseTable
import store.swust.swustmeow.components.course_table.CourseTableHeaderRow
import store.swust.swustmeow.data.CourseTableState
import store.swust.swustmeow.entities.SimpleCourseEntry
import store.swust.swustmeow.providers.CourseTableDataProvider
import store.swust.swustmeow.services.WidgetsDatabaseHelper
import java.util.Date
import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.Locale

class CourseTableWidget : GlanceAppWidget() {
    override val stateDefinition = CourseTableWidgetStateDefinition()
    private lateinit var db: WidgetsDatabaseHelper

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        db = WidgetsDatabaseHelper(context)

        provideContent {
            CourseTableWidgetContent(context, currentState())
        }
    }

    @Suppress("UNUSED_PARAMETER", "UNCHECKED_CAST")
    @Composable
    private fun CourseTableWidgetContent(context: Context, currentState: CourseTableWidgetState) {
        val isFirst = remember { mutableStateOf(true) }
        val currentTimestamp = remember { mutableStateOf(0L) }
        val success = remember { mutableStateOf(false) }
        val lastUpdateTimestamp = remember { mutableStateOf(0L) }
        val weekNum = remember { mutableStateOf(0) }
        val termStartDate = remember { mutableStateOf(Date()) }
        val entries = remember { mutableStateOf<List<SimpleCourseEntry>?>(null) }
        val courseTableTimes = remember { mutableStateOf<List<String>?>(null) }
        val term = remember { mutableStateOf("") }

        LaunchedEffect(key1 = currentTimestamp.value) {
            CoroutineScope(Dispatchers.Main).launch {
                if (!isFirst.value) {
                    delay(60 * 1000)
                }

                isFirst.value = false

                withContext(Dispatchers.IO) {
                    currentTimestamp.value = System.currentTimeMillis()

                    val data = db.query()
                    val gson = Gson()

                    success.value = (data?.courseTableSuccess ?: 0) == 1
                    lastUpdateTimestamp.value = data?.courseTableLastUpdateTimestamp ?: 0L

                    val entriesList = data?.courseTableEntriesJson
                    val entriesMaps = try {
                        if (entriesList != null) gson.fromJson(
                            entriesList,
                            List::class.java
                        ) else null
                    } catch (e: Exception) {
                        null
                    } as List<Map<String, *>>?

                    entries.value = try {
                        entriesMaps?.map {
                            SimpleCourseEntry(
                                name = it["course_name"] as String,
                                place = it["place"] as String,
                                color = (it["color"] as Double).toLong(),
                                weekday = (it["weekday"] as Double).toInt(),
                                startWeek = (it["start_week"] as Double).toInt(),
                                endWeek = (it["end_week"] as Double).toInt(),
                                numberOfDay = (it["number_of_day"] as Double).toInt(),
                                startSection = (it["start_section"] as Double).toInt(),
                                endSection = (it["end_section"] as Double).toInt(),
                            )
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        null
                    }

                    weekNum.value = data?.courseTableWeekNum ?: 0
                    CourseTableState.weekNum = weekNum.value

                    termStartDate.value = data?.courseTableTermStartDate?.let {
                        try {
                            SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).parse(it)
                        } catch (e: Exception) {
                            Date()
                        }
                    } ?: Date()
                    courseTableTimes.value = data?.courseTableTimesJson?.let {
                        try {
                            gson.fromJson(it, List::class.java) as List<String>
                        } catch (e: Exception) {
                            emptyList()
                        }
                    } ?: emptyList()
                    term.value = data?.courseTableTerm ?: ""
                }
            }
        }

        val provider = CourseTableDataProvider(
            weekNum = weekNum.value,
            termStartDate = termStartDate.value,
            entries = entries.value ?: emptyList(),
            courseTableTimes = courseTableTimes.value ?: emptyList(),
            term = term.value
        )

        Box(
            modifier = GlanceModifier.cornerRadius(16.dp).background(Color.White)
                .fillMaxSize().padding(all = 4.dp),
            contentAlignment = Alignment.Center
        ) {
            if (success.value) {
                Column(
                    modifier = GlanceModifier.fillMaxSize(),
                    verticalAlignment = Alignment.Vertical.CenterVertically
                ) {
                    CourseTableHeaderRow(provider = provider, weekNum = CourseTableState.weekNum)
                    Box(modifier = GlanceModifier.fillMaxSize()) {
                        CourseTable(provider = provider)
                    }
                }
            } else {
                CourseLoadErrorBox()
            }
        }
    }
}
