package store.swust.swustmeow.data

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

object Values {
    val primaryColor: Color = Color(27, 122, 222)
    val secondaryColor: Color = Color.Black.copy(alpha = 0.6F)
    private val basePadding: Dp = 10.dp
    val smallestSpacer: Dp = basePadding * 0.2F
    val smallerSpacer: Dp = basePadding * 0.4F
    val smallSpacer: Dp = basePadding * 0.7F
    val mediumSpacer: Dp = basePadding * 0.9F
    val normalSpacer: Dp = basePadding * 1F
    val largerSpacer: Dp = basePadding * 1.2F
}