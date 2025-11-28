package store.swust.swustmeow.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

@Composable
fun CourseLoadErrorBox() {
    Box(
        modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center
    ) {
        Text(
            text = "课程表获取失败",
            style = TextStyle(
                color = ColorProvider(Color.Black),
                fontSize = 16.sp,
                textAlign = TextAlign.Center
            ),
        )
    }
}