package store.swust.swustmeow.widgets.course_table

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

class CourseTableWidgetStateDefinition : GlanceStateDefinition<CourseTableWidgetState> {
    private fun Context.courseTableWidgetDataStoreFile(fileKey: String) =
        dataStoreFile("course_table_widget_$fileKey")

    override suspend fun getDataStore(
        context: Context,
        fileKey: String
    ): DataStore<CourseTableWidgetState> {
        return DataStoreFactory.create(serializer = CourseTableWidgetStateSerializer) {
            context.courseTableWidgetDataStoreFile(fileKey)
        }
    }

    override fun getLocation(context: Context, fileKey: String): File {
        return context.courseTableWidgetDataStoreFile(fileKey)
    }

    object CourseTableWidgetStateSerializer : Serializer<CourseTableWidgetState> {
        private val gson by lazy {
            GsonBuilder().create()
        }

        override val defaultValue = CourseTableWidgetState()

        override suspend fun readFrom(input: InputStream): CourseTableWidgetState = try {
            val jsonString = input.readBytes().decodeToString()
            val state = gson.fromJson<CourseTableWidgetState>(
                jsonString,
                object : TypeToken<CourseTableWidgetState>() {}.type
            )
            state
        } catch (e: Exception) {
            defaultValue
        }

        override suspend fun writeTo(t: CourseTableWidgetState, output: OutputStream) {
            output.use {
                it.write(gson.toJson(t).encodeToByteArray())
            }
        }
    }
}