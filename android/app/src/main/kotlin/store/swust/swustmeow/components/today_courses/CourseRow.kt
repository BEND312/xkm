package store.swust.swustmeow.components.today_courses

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import store.swust.swustmeow.components.MonospacedText
import store.swust.swustmeow.data.Values
import store.swust.swustmeow.entities.SingleCourse

@Composable
fun CourseRow(course: SingleCourse, mini: Boolean = false) {
    val times = course.time.split("-")
    val startTime = times.first().split(":")
    val endTime = times.last().split(":")
    val timeStyle = TextStyle(
        fontSize = if (!mini) 12.sp else 10.sp,
        textAlign = TextAlign.Center,
    )
    val width = if (!mini) 8.dp else 7.dp

    Row(modifier = GlanceModifier.fillMaxWidth()) {
        Column {
            Row {
                MonospacedText(
                    startTime.first(),
                    width = width,
                    style = timeStyle,
                )
                Text(":", style = timeStyle)
                MonospacedText(
                    startTime.last(),
                    width = width,
                    style = timeStyle,
                )
            }
            Spacer(modifier = GlanceModifier.height(Values.smallestSpacer))
            Row {
                MonospacedText(
                    endTime.first(),
                    width = width,
                    style = timeStyle.copy(color = ColorProvider(Color.Gray)),
                )
                Text(":", style = timeStyle.copy(color = ColorProvider(Color.Gray)))
                MonospacedText(
                    endTime.last(),
                    width = width,
                    style = timeStyle.copy(color = ColorProvider(Color.Gray)),
                )
            }
        }
        Spacer(modifier = GlanceModifier.width(if (!mini) Values.mediumSpacer else Values.smallerSpacer))
        Box(
            modifier = GlanceModifier.background(Color(course.color.toLong())).cornerRadius(8.dp)
                .width(if (!mini) 4.dp else 2.dp)
                .height((2 * (if (!mini) 16 else 14) + Values.smallestSpacer.value).dp)
        ) {}
        Spacer(modifier = GlanceModifier.width(if (!mini) Values.mediumSpacer else Values.smallerSpacer))
        Column(modifier = GlanceModifier.defaultWeight()) {
            Text(
                course.name,
                style = TextStyle(
                    color = ColorProvider(Color.Black),
                    fontSize = if (!mini) 14.sp else 12.sp,
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 1
            )
            Spacer(modifier = GlanceModifier.height(Values.smallestSpacer))
            Text(
                course.place,
                style = TextStyle(
                    color = ColorProvider(Color.Gray),
                    fontSize = if (!mini) 12.sp else 10.sp,
                ),
                maxLines = 1
            )
        }
    }
}