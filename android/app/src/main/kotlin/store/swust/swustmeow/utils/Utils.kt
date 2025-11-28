package store.swust.swustmeow.utils

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.ContextCompat.startActivity

suspend fun <T> tryDoSuspend(retries: Int = 3, block: suspend () -> T): T? {
    var attempts = 0

    while (attempts < retries) {
        try {
            return block()
        } catch (e: Exception) {
            attempts++
            if (attempts == retries) {
                e.printStackTrace()
                return null
            }
        }
    }

    return null
}

fun jumpToCourseTablePage(context: Context) {
    val url = "smeow://jump/course_table"
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
    startActivity(context, intent, null)
}
