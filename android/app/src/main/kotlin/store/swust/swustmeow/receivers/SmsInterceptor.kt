/*
 * Copyright (c) 2025 BEND
 *
 * This file is a new addition to the project, created as part of secondary development.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

package store.swust.swustmeow.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log

class SmsInterceptor : BroadcastReceiver() {

    companion object {
        private const val TAG = "SmsInterceptor"  
        interface OnSmsReceivedListener {
            fun onSmsReceived(sender: String, message: String, timestamp: Long)
        }
        private val listeners = mutableListOf<OnSmsReceivedListener>()
        fun addListener(listener: OnSmsReceivedListener) {
            synchronized(listeners) {
                if (!listeners.contains(listener)) {
                    listeners.add(listener)
                }
            }
        }
        fun removeListener(listener: OnSmsReceivedListener) {
            synchronized(listeners) {
                listeners.remove(listener)
            }
        }
        
        fun clearListeners() {
            synchronized(listeners) {
                listeners.clear()
            }
        }
        
        private fun notifyListeners(sender: String, message: String, timestamp: Long) {
            synchronized(listeners) {
                listeners.forEach { listener ->
                    try {
                        listener.onSmsReceived(sender, message, timestamp)
                    } catch (e: Exception) {
                    }
                }
            }
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }

        context ?: return
        
        try {
            val messages = extractSmsMessages(intent)
            
            if (messages.isEmpty()) {
                return
            }
            messages.forEach { sms ->
                val sender = sms.originatingAddress ?: "未知号码"
                val body = sms.messageBody ?: ""
                val timestamp = sms.timestampMillis
                processSms(context, sender, body, timestamp)
                notifyListeners(sender, body, timestamp)
            }
            
        } catch (e: Exception) {
            // 忽略处理异常
        }
    }

    private fun extractSmsMessages(intent: Intent): List<SmsMessage> {
        val messages = mutableListOf<SmsMessage>()
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                val smsMessages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                if (smsMessages != null) {
                    messages.addAll(smsMessages)
                }
            } else {
                val pdus = intent.extras?.get("pdus") as? Array<*>
                pdus?.forEach { pdu ->
                    if (pdu is ByteArray) {
                        @Suppress("DEPRECATION")
                        val sms = SmsMessage.createFromPdu(pdu)
                        messages.add(sms)
                    }
                }
            }
        } catch (e: Exception) {
            // 忽略提取异常
        }
        
        return messages
    }

    private fun processSms(context: Context, sender: String, body: String, timestamp: Long) {
        when {
            body.contains("西南科技大学") -> {
                handleSwustSms(context, sender, body, timestamp)
            }
            body.contains("验证码") -> {
                handleVerificationCodeSms(context, sender, body, timestamp)
            }
            else -> {
                // 其他短信不处理
            }
        }
    }

    private fun handleSwustSms(context: Context, sender: String, body: String, timestamp: Long) {
        extractVerificationCode(body)?.let { code ->
        }
    }

    /**
     * 处理验证码短信
     */
    private fun handleVerificationCodeSms(context: Context, sender: String, body: String, timestamp: Long) {
        extractVerificationCode(body)?.let { code ->
        }
    }

    private fun extractVerificationCode(body: String): String? {
        // 常见验证码格式的正则表达式
        val patterns = listOf(
            Regex("验证码[：:为是]?\\s*(\\d{4,8})"),           // 验证码：123456
            Regex("验证码[：:为是]?\\s*([A-Za-z0-9]{4,8})"),   // 验证码：ABC123
            Regex("code[：:为是]?\\s*(\\d{4,8})", RegexOption.IGNORE_CASE),  // code:123456
            Regex("\\b(\\d{6})\\b"),                           // 独立的6位数字
            Regex("\\b(\\d{4})\\b")                            // 独立的4位数字
        )
        
        patterns.forEach { pattern ->
            pattern.find(body)?.let { matchResult ->
                val code = matchResult.groupValues.getOrNull(1)
                if (!code.isNullOrEmpty()) {
                    return code
                }
            }
        }
        
        return null
    }
}
