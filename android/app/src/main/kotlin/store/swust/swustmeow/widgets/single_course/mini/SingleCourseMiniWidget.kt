package store.swust.swustmeow.widgets.single_course.mini

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
import store.swust.swustmeow.components.single_course.CourseLocationRow
import store.swust.swustmeow.components.single_course.CourseStatusRow
import store.swust.swustmeow.components.single_course.CourseTimeRow
import store.swust.swustmeow.components.single_course.NoCourseBox
import store.swust.swustmeow.data.Values
import store.swust.swustmeow.entities.SingleCourse
import store.swust.swustmeow.providers.SingleCourseDataProvider
import store.swust.swustmeow.services.WidgetsDatabaseHelper
import store.swust.swustmeow.utils.TimeUtils
import store.swust.swustmeow.utils.jumpToCourseTablePage
import store.swust.swustmeow.widgets.single_course.SingleCourseWidgetStateDefinition

class SingleCourseMiniWidget : GlanceAppWidget() {
    override val stateDefinition = SingleCourseWidgetStateDefinition()
    private lateinit var db: WidgetsDatabaseHelper

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        db = WidgetsDatabaseHelper(context)

        provideContent {
            SingleCourseMiniWidgetContent(context)
        }
    }

    @Composable
    private fun SingleCourseMiniWidgetContent(context: Context) {
        val isFirst = remember { mutableStateOf(true) }
        val currentTimestamp = remember { mutableStateOf(0L) }
        val success = remember { mutableStateOf(false) }
        val lastUpdateTimestamp = remember { mutableStateOf(0L) }
        val currentCourse = remember { mutableStateOf<SingleCourse?>(null) }
        val nextCourse = remember { mutableStateOf<SingleCourse?>(null) }
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

                    success.value = (data?.singleCourseSuccess ?: 0) == 1
                    lastUpdateTimestamp.value = data?.singleCourseLastUpdateTimestamp ?: 0L

                    currentCourse.value = try {
                        val json =
                            gson.fromJson(data?.singleCourseCurrentCourseJson, Map::class.java)
                        val name = json?.get("name") as String?
                        val place = json?.get("place") as String?
                        val time = json?.get("time") as String?
                        val diff = json?.get("diff") as String?
                        val color = json?.get("color") as String?

                        if (json != null && name != null && place != null && time != null && diff != null && color != null) {
                            SingleCourse(
                                name = name,
                                place = place,
                                time = time,
                                diff = diff,
                                color = color
                            )
                        } else null
                    } catch (e: Exception) {
                        null
                    }

                    nextCourse.value = try {
                        val json =
                            gson.fromJson(data?.singleCourseNextCourseJson, Map::class.java)
                        val name = json?.get("name") as String?
                        val place = json?.get("place") as String?
                        val time = json?.get("time") as String?
                        val diff = json?.get("diff") as String?
                        val color = json?.get("color") as String?

                        if (json != null && name != null && place != null && time != null && diff != null && color != null) {
                            SingleCourse(
                                name = name,
                                place = place,
                                time = time,
                                diff = diff,
                                color = color
                            )
                        } else null
                    } catch (e: Exception) {
                        null
                    }

                    weekNum.value = data?.singleCourseWeekNum ?: 0
                }
            }
        }

        val date = TimeUtils.getCurrentMD()
        val weekday = TimeUtils.getWeekdayDisplayString()

        val provider = SingleCourseDataProvider(
            date = date,
            weekday = weekday,
            weekNum = weekNum.value,
            currentCourse = currentCourse.value,
            nextCourse = nextCourse.value,
        )

        Box(
            modifier = GlanceModifier.cornerRadius(16.dp)
                .padding(horizontal = 16.dp, vertical = 16.dp).background(Color.White)
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
                    if (!success.value) {
                        CourseLoadErrorBox()
                    } else if (currentCourse.value == null && nextCourse.value == null) {
                        NoCourseBox()
                    } else {
                        CourseStatusRow(provider = provider, showLeftTime = false)
                        Spacer(modifier = GlanceModifier.height(Values.smallSpacer))
                        CourseNameRow(provider = provider)
                        Spacer(modifier = GlanceModifier.height(Values.smallSpacer))
                        BottomInformationColumn(provider = provider)
                    }
                }
            }
        }
    }

    @Composable
    private fun HeaderRow(provider: SingleCourseDataProvider) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Vertical.CenterVertically
        ) {
            Text(
                text = provider.date,
                modifier = GlanceModifier.defaultWeight(),
                style = TextStyle(
                    color = ColorProvider(Color.Black),
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 1
            )
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

    @Composable
    private fun CourseNameRow(provider: SingleCourseDataProvider) {
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            Text(
                text = provider.currentCourse?.name ?: provider.nextCourse?.name ?: "",
                style = TextStyle(
                    color = ColorProvider(Color.Black),
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp,
                ),
                maxLines = 1
            )
        }
    }

    @Composable
    private fun BottomInformationColumn(provider: SingleCourseDataProvider) {
        Column(
            modifier = GlanceModifier.fillMaxWidth(),
            horizontalAlignment = Alignment.Horizontal.Start
        ) {
            CourseLocationRow(provider = provider, modifier = GlanceModifier)
            Spacer(modifier = GlanceModifier.width(Values.smallSpacer))
            CourseTimeRow(provider = provider)
        }
    }
}