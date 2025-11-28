package store.swust.swustmeow.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.Dp
import androidx.glance.GlanceModifier
import androidx.glance.layout.Row
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextStyle

@Composable
fun MonospacedText(
    text: String,
    width: Dp,
    style: TextStyle = TextStyle()
) {
    Row {
        text.forEach { char ->
            Text(
                char.toString(),
                modifier = GlanceModifier.width(width),
                style = style
            )
        }
    }
}