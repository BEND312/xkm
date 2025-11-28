package store.swust.swustmeow.components.single_course

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import store.swust.swustmeow.data.Values

@Composable
fun NoCourseBox() {
    Box(
        modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "今天没有课啦",
                style = TextStyle(
                    color = ColorProvider(Color.Black.copy(alpha = 0.6F)),
                    fontSize = 14.sp,
                    textAlign = TextAlign.Center
                ),
            )
            Spacer(modifier = GlanceModifier.height(Values.smallSpacer))
            Text(
                text = "好好休息吧",
                style = TextStyle(
                    color = ColorProvider(Color.Black.copy(alpha = 0.6F)),
                    fontSize = 14.sp,
                    textAlign = TextAlign.Center
                ),
            )
        }
    }
}