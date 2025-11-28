package store.swust.swustmeow.widgets.single_course

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

class SingleCourseWidgetStateDefinition : GlanceStateDefinition<SingleCourseWidgetState> {
    private fun Context.singleCourseWidgetDataStoreFile(fileKey: String) =
        dataStoreFile("single_course_widget_$fileKey")

    override suspend fun getDataStore(
        context: Context,
        fileKey: String
    ): DataStore<SingleCourseWidgetState> {
        return DataStoreFactory.create(serializer = SingleCourseWidgetStateSerializer) {
            context.singleCourseWidgetDataStoreFile(fileKey)
        }
    }

    override fun getLocation(context: Context, fileKey: String): File {
        return context.singleCourseWidgetDataStoreFile(fileKey)
    }

    object SingleCourseWidgetStateSerializer : Serializer<SingleCourseWidgetState> {
        private val gson by lazy {
            GsonBuilder().create()
        }

        override val defaultValue = SingleCourseWidgetState()

        override suspend fun readFrom(input: InputStream): SingleCourseWidgetState = try {
            val jsonString = input.readBytes().decodeToString()
            val state = gson.fromJson<SingleCourseWidgetState>(
                jsonString,
                object : TypeToken<SingleCourseWidgetState>() {}.type
            )
            state
        } catch (e: Exception) {
            defaultValue
        }

        override suspend fun writeTo(t: SingleCourseWidgetState, output: OutputStream) {
            output.use {
                it.write(gson.toJson(t).encodeToByteArray())
            }
        }
    }
}