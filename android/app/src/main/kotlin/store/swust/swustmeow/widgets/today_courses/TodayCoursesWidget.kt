package store.swust.swustmeow.widgets.today_courses

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import store.swust.swustmeow.components.CourseLoadErrorBox
import store.swust.swustmeow.components.today_courses.CourseRow
import store.swust.swustmeow.components.today_courses.NoCourseBox
import store.swust.swustmeow.data.Values
import store.swust.swustmeow.entities.SingleCourse
import store.swust.swustmeow.providers.TodayCoursesDataProvider
import store.swust.swustmeow.services.WidgetsDatabaseHelper
import store.swust.swustmeow.utils.TimeUtils
import store.swust.swustmeow.utils.jumpToCourseTablePage

class TodayCoursesWidget : GlanceAppWidget() {
    override val stateDefinition = TodayCoursesWidgetStateDefinition()
    private lateinit var db: WidgetsDatabaseHelper

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        db = WidgetsDatabaseHelper(context)

        provideContent {
            TodayCoursesWidgetContent(context)
        }
    }

    @Suppress("UNCHECKED_CAST")
    @Composable
    private fun TodayCoursesWidgetContent(context: Context) {
        val isFirst = remember { mutableStateOf(true) }
        val currentTimestamp = remember { mutableStateOf(0L) }
        val success = remember { mutableStateOf(false) }
        val lastUpdateTimestamp = remember { mutableStateOf(0L) }
        val todayCourses = remember { mutableStateOf<List<SingleCourse>?>(null) }
        val weekNum = remember { mutableStateOf(0) }

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

                    success.value = (data?.todayCoursesSuccess ?: 0) == 1
                    lastUpdateTimestamp.value = data?.todayCoursesLastUpdateTimestamp ?: 0L

                    val todayCoursesList = data?.todayCoursesTodayCoursesList
                    val todayCoursesMaps = try {
                        if (todayCoursesList != null) gson.fromJson(
                            todayCoursesList,
                            List::class.java
                        ) else null
                    } catch (e: Exception) {
                        null
                    } as List<Map<String, *>>?

                    todayCourses.value = try {
                        todayCoursesMaps?.map {
                            SingleCourse(
                                name = it["name"] as String,
                                place = it["place"] as String,
                                time = it["time"] as String,
                                diff = it["diff"] as String?,
                                color = it["color"] as String
                            )
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        null
                    }

                    weekNum.value = data?.todayCoursesWeekNum ?: 0
                }
            }
        }


        val date = TimeUtils.getCurrentMD()
        val weekday = TimeUtils.getWeekdayDisplayString()

        val provider = TodayCoursesDataProvider(
            date = date,
            weekday = weekday,
            weekNum = weekNum.value,
        )

        Box(
            modifier = GlanceModifier.cornerRadius(16.dp)
                .padding(horizontal = 20.dp, vertical = 16.dp).background(Color.White)
                .fillMaxSize().clickable {
                    jumpToCourseTablePage(context)
                },
            contentAlignment = Alignment.Center
        ) {
            Column {
                HeaderRow(provider = provider)
                Spacer(modifier = GlanceModifier.height(Values.mediumSpacer))
                Column(
                    verticalAlignment = Alignment.Vertical.CenterVertically,
                    horizontalAlignment = Alignment.Horizontal.CenterHorizontally
                ) {
                    if (!success.value || todayCourses.value == null) {
                        CourseLoadErrorBox()
                    } else if (todayCourses.value!!.isEmpty()) {
                        NoCourseBox()
                    } else {
                        LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
                            items(todayCourses.value!!.size) { index ->
                                Column(modifier = GlanceModifier.clickable {
                                    jumpToCourseTablePage(context)
                                }) {
                                    CourseRow(course = todayCourses.value!![index])
                                    if (index < todayCourses.value!!.size - 1) {
                                        Spacer(modifier = GlanceModifier.height(Values.smallSpacer))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun HeaderRow(provider: TodayCoursesDataProvider) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Vertical.CenterVertically
        ) {
            Text(
                text = "${provider.date}    今日课表",
                modifier = GlanceModifier.defaultWeight(),
                style = TextStyle(
                    color = ColorProvider(Color.Black),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 1
            )
            Spacer(modifier = GlanceModifier.width(Values.smallSpacer))
            Text(
                text = "第${provider.weekNum}周",
                style = TextStyle(
                    color = ColorProvider(Color.Black),
                    fontSize = 14.sp,
                    textAlign = TextAlign.End
                ),
                maxLines = 1
            )
        }
    }
}