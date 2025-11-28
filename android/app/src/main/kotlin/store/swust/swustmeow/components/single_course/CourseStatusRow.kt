package store.swust.swustmeow.components.single_course

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import store.swust.swustmeow.data.Values
import store.swust.swustmeow.providers.SingleCourseDataProvider

@Composable
fun CourseStatusRow(provider: SingleCourseDataProvider, showLeftTime: Boolean = true) {
    val color = if (provider.currentCourse != null) Color(
        34, 197, 94
    ) else Color(197, 175, 34)

    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.Vertical.CenterVertically
    ) {
        Box(
            modifier = GlanceModifier.background(color).cornerRadius(8.dp).width(4.dp).height(14.dp)
        ) {}
        Spacer(modifier = GlanceModifier.width(Values.smallSpacer))
        Text(
            text = if (provider.currentCourse != null) "正在上课" else ("下节课" + if (showLeftTime) "（${provider.nextCourse?.diff}后）" else ""),
            modifier = GlanceModifier.fillMaxWidth(),
            style = TextStyle(
                color = ColorProvider(color), fontSize = 14.sp, fontWeight = FontWeight.Bold
            ),
            maxLines = 1
        )
    }
}