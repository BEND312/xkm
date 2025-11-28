package store.swust.swustmeow.components.course_table

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import store.swust.swustmeow.R
import store.swust.swustmeow.data.CourseTableState
import store.swust.swustmeow.data.Values
import store.swust.swustmeow.providers.CourseTableDataProvider
import store.swust.swustmeow.utils.TimeUtils
import store.swust.swustmeow.utils.add
import store.swust.swustmeow.utils.day
import store.swust.swustmeow.utils.month
import store.swust.swustmeow.utils.padL2
import java.time.Duration

@Composable
fun CourseTableHeaderRow(provider: CourseTableDataProvider, weekNum: Int) {
    val days = arrayOf("一", "二", "三", "四", "五", "六", "日")
    val startDate = provider.termStartDate
    val baseDate = startDate.add(Duration.ofDays(7 * (weekNum - 1).toLong()))
    val style = TextStyle(
        fontSize = 9.sp,
        color = ColorProvider(Color.Black)
    )
    val iconSize = 24.dp
    val date = TimeUtils.getCurrentYMD()
    val term = provider.term

    Column(modifier = GlanceModifier.fillMaxWidth().padding(all = 4.dp)) {
        Row(
            modifier = GlanceModifier.fillMaxWidth().padding(all = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = date,
                    style = TextStyle(
                        color = ColorProvider(Color.Black),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    modifier = GlanceModifier.defaultWeight()
                )
                Spacer(modifier = GlanceModifier.width(Values.mediumSpacer))
                Text(
                    text = term,
                    style = TextStyle(
                        color = ColorProvider(Color.Black.copy(alpha = 0.6F)),
                        fontSize = 11.sp,
                    ),
                    modifier = GlanceModifier.defaultWeight()
                )
            }
            Row(horizontalAlignment = Alignment.End) {
                Text(
                    text = "本周课表",
                    style = TextStyle(
                        color = ColorProvider(Color.Black),
                        fontSize = 14.sp,
                    ),
                )
//                Image(
//                    provider = ImageProvider(R.drawable.setting),
//                    contentDescription = "设置",
//                    modifier = GlanceModifier.defaultWeight().size(iconSize).clickable { },
//                    contentScale = ContentScale.Fit,
//                )
//                Spacer(modifier = GlanceModifier.width(Values.normalSpacer))
//                Image(
//                    provider = ImageProvider(R.drawable.left_arrow),
//                    contentDescription = "上一周",
//                    modifier = GlanceModifier.defaultWeight().size(iconSize).clickable {
//                        if (CourseTableState.weekNum >= 1) {
//                            CourseTableState.weekNum--
//                        }
//                    },
//                    contentScale = ContentScale.Fit,
//                )
//                Spacer(modifier = GlanceModifier.width(Values.normalSpacer))
//                Image(
//                    provider = ImageProvider(R.drawable.righ_arrow),
//                    contentDescription = "下一周",
//                    modifier = GlanceModifier.defaultWeight().size(iconSize).clickable {
//                        if (CourseTableState.weekNum <= 30) {
//                            CourseTableState.weekNum++
//                        }
//                    },
//                    contentScale = ContentScale.Fit,
//                )
            }
        }
        Spacer(modifier = GlanceModifier.width(Values.mediumSpacer))
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(modifier = GlanceModifier.padding(start = 6.dp, end = 2.dp)) {
                Text(
                    text = "${weekNum.padL2()}周",
                    style = TextStyle(
                        fontSize = 10.sp
                    )
                )
            }
            days.forEachIndexed { i, _ ->
                val t = baseDate.add(Duration.ofDays(i.toLong()))
                Box(
                    modifier = GlanceModifier.defaultWeight(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = days[i],
                            style = style
                        )
                        Text(
                            "${t.month().padL2()}/${t.day().padL2()}",
                            style = style
                        )
                    }
                }
            }
        }
    }
}
