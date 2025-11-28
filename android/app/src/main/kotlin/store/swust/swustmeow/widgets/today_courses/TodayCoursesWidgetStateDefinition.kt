package store.swust.swustmeow.widgets.today_courses

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.core.DataStoreFactory
import androidx.datastore.core.Serializer
import androidx.datastore.dataStoreFile
import androidx.glance.state.GlanceStateDefinition
import com.google.gson.GsonBuilder
import com.google.gson.reflect.TypeToken
import java.io.File
import java.io.InputStream
import java.io.OutputStream

class TodayCoursesWidgetStateDefinition : GlanceStateDefinition<TodayCoursesWidgetState> {
    private fun Context.todayCoursesWidgetDataStoreFile(fileKey: String) =
        dataStoreFile("today_courses_widget_$fileKey")

    override suspend fun getDataStore(
        context: Context,
        fileKey: String
    ): DataStore<TodayCoursesWidgetState> {
        return DataStoreFactory.create(serializer = TodayCoursesWidgetStateSerializer) {
            context.todayCoursesWidgetDataStoreFile(fileKey)
        }
    }

    override fun getLocation(context: Context, fileKey: String): File {
        return context.todayCoursesWidgetDataStoreFile(fileKey)
    }

    object TodayCoursesWidgetStateSerializer : Serializer<TodayCoursesWidgetState> {
        private val gson by lazy {
            GsonBuilder().create()
        }

        override val defaultValue = TodayCoursesWidgetState()

        override suspend fun readFrom(input: InputStream): TodayCoursesWidgetState = try {
            val jsonString = input.readBytes().decodeToString()
            val state = gson.fromJson<TodayCoursesWidgetState>(
                jsonString,
                object : TypeToken<TodayCoursesWidgetState>() {}.type
            )
            state
        } catch (e: Exception) {
            defaultValue
        }

        override suspend fun writeTo(t: TodayCoursesWidgetState, output: OutputStream) {
            output.use {
                it.write(gson.toJson(t).encodeToByteArray())
            }
        }
    }
}