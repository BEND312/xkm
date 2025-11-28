/*
 * Copyright (c) 2025 BEND
 *
 * This file is a new addition to the project, created as part of secondary development.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

package store.swust.swustmeow.utils

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony


object SmsReaderUtil {
    
    data class SmsMessage(
        val id: String,
        val address: String,
        val body: String,
        val date: Long,
        val type: Int
    )
    
    fun getSwustMessages(context: Context, limit: Int = 100): List<SmsMessage> {
        val messages = mutableListOf<SmsMessage>()
        
        try {
            val uri: Uri = Telephony.Sms.CONTENT_URI
            val projection = arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.TYPE
            )
            val cursor: Cursor? = context.contentResolver.query(
                uri,
                projection,
                null,
                null,
                "${Telephony.Sms.DATE} DESC"
            )
            
            cursor?.use {
                val idIndex = it.getColumnIndex(Telephony.Sms._ID)
                val addressIndex = it.getColumnIndex(Telephony.Sms.ADDRESS)
                val bodyIndex = it.getColumnIndex(Telephony.Sms.BODY)
                val dateIndex = it.getColumnIndex(Telephony.Sms.DATE)
                val typeIndex = it.getColumnIndex(Telephony.Sms.TYPE)
                
                while (it.moveToNext() && messages.size < limit) {
                    val body = it.getString(bodyIndex) ?: ""

                    if (body.contains("西南科技大学")) {
                        val message = SmsMessage(
                            id = it.getString(idIndex) ?: "",
                            address = it.getString(addressIndex) ?: "",
                            body = body,
                            date = it.getLong(dateIndex),
                            type = it.getInt(typeIndex)
                        )
                        messages.add(message)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return messages
    }

    fun getRecentSwustMessages(context: Context, count: Int): List<SmsMessage> {
        return getSwustMessages(context, count)
    }
    
    fun messagesToMapList(messages: List<SmsMessage>): List<Map<String, Any>> {
        return messages.map { message ->
            mapOf(
                "id" to message.id,
                "address" to message.address,
                "body" to message.body,
                "date" to message.date,
                "type" to message.type
            )
        }
    }
    
    fun hasMessagesWithKeyword(context: Context, keyword: String): Boolean {
        try {
            val uri: Uri = Telephony.Sms.CONTENT_URI
            val projection = arrayOf(Telephony.Sms.BODY)
            val selection = "${Telephony.Sms.BODY} LIKE ?"
            val selectionArgs = arrayOf("%$keyword%")
            
            val cursor: Cursor? = context.contentResolver.query(
                uri,
                projection,
                selection,
                selectionArgs,
                "${Telephony.Sms.DATE} DESC LIMIT 1"
            )
            
            cursor?.use {
                return it.count > 0
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return false
    }
}
