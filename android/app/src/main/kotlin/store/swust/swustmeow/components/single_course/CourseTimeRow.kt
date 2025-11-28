package store.swust.swustmeow.components.single_course

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.height
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import store.swust.swustmeow.R
import store.swust.swustmeow.data.Values
import store.swust.swustmeow.providers.SingleCourseDataProvider

@Composable
fun CourseTimeRow(provider: SingleCourseDataProvider) {
    Row(
        verticalAlignment = Alignment.Vertical.CenterVertically
    ) {
        Image(
            provider = ImageProvider(R.drawable.time),
            contentDescription = "clock_icon",
            modifier = GlanceModifier.width(14.dp).height(14.dp),
            colorFilter = ColorFilter.tint(ColorProvider(Values.primaryColor))
        )
        Spacer(modifier = GlanceModifier.width(Values.smallSpacer))
        Text(
            text = provider.currentCourse?.time ?: provider.nextCourse?.time ?: "",
            style = TextStyle(
                color = ColorProvider(Values.primaryColor.copy(alpha = 0.8F)),
                fontSize = 14.sp,
                textAlign = TextAlign.End
            ),
            maxLines = 1
        )
    }
}