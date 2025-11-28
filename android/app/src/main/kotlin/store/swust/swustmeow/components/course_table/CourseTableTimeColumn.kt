package store.swust.swustmeow.components.course_table

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import store.swust.swustmeow.providers.CourseTableDataProvider

@Composable
fun CourseTableTimeColumn(
    provider: CourseTableDataProvider,
    indexOfDay: Int,
    width: Dp,
    height: Dp
) {
    val times = provider.courseTableTimes
    if (times.isEmpty()) return Box {}

    Box(
        modifier = GlanceModifier.width(width).height(height),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(modifier = GlanceModifier.padding(all = 4.dp)) {}
            Text(
                text = (indexOfDay + 1).toString(),
                style = TextStyle(
                    fontSize = 10.sp,
                    textAlign = TextAlign.Center
                )
            )
            Text(
                text = times[indexOfDay],
                style = TextStyle(
                    fontSize = 8.sp,
                    textAlign = TextAlign.Center
                )
            )
        }
    }
}