package store.swust.swustmeow.components.course_table

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import store.swust.swustmeow.entities.SimpleCourseEntry

@Composable
fun CourseCard(course: SimpleCourseEntry, height: Dp) {
    val color = Color(course.color)
    val textColor = if (color.luminance() > 0.7) Color.Black else Color.White
    val secondaryColor = textColor.copy(alpha = 0.8F)

    Box(
        modifier = GlanceModifier.padding(all = 4.dp)
            .background(color)
            .cornerRadius(6.dp)
            .height(height - 1.dp)
    ) {
        Column {
            Text(
                text = course.name,
                style = TextStyle(
                    color = ColorProvider(textColor),
                    fontSize = 10.sp,
                ),
                maxLines = 4,
                modifier = GlanceModifier
            )
            Text(
                text = "@${course.place}",
                style = TextStyle(
                    color = ColorProvider(secondaryColor),
                    fontSize = 9.sp,
                ),
                maxLines = 4
            )
        }
    }
}