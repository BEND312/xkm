/*
 * Copyright (c) 2025 BEND
 *
 * This file is a secondary development based on the original project.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

package store.swust.swustmeow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.provider.Telephony
import android.telephony.SmsMessage
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import store.swust.swustmeow.utils.AppLauncherUtil
import store.swust.swustmeow.utils.SmsReaderUtil
import store.swust.swustmeow.receivers.SmsInterceptor

class MainActivity : FlutterActivity() {
    private val APP_LAUNCHER_CHANNEL = "store.swust.swustmeow/app_launcher"
    private val SMS_READER_CHANNEL = "store.swust.swustmeow/sms_reader"
    private val SMS_INTERCEPTOR_CHANNEL = "store.swust.swustmeow/sms_interceptor"
    
    private val SMS_PERMISSION_REQUEST_CODE = 100
    private var smsInterceptorMethodChannel: MethodChannel? = null
    private val smsListener = object : SmsInterceptor.Companion.OnSmsReceivedListener {
        override fun onSmsReceived(sender: String, message: String, timestamp: Long) {
            runOnUiThread {
                smsInterceptorMethodChannel?.invokeMethod("onSmsReceived", mapOf(
                    "sender" to sender,
                    "body" to message,
                    "timestamp" to timestamp
                ))
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchAppByPackageName" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val success = AppLauncherUtil.launchAppByPackageName(this, packageName)
                        if (success) {
                            result.success(true)
                        } else {
                            result.error("LAUNCH_FAILED", "无法启动应用：$packageName", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "包名不能为空", null)
                    }
                }
                "launchAppByUri" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        val success = AppLauncherUtil.launchAppByUri(this, uri)
                        if (success) {
                            result.success(true)
                        } else {
                            result.error("LAUNCH_FAILED", "无法通过URI启动应用：$uri", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI不能为空", null)
                    }
                }
                "isAppInstalled" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val isInstalled = AppLauncherUtil.isAppInstalled(this, packageName)
                        result.success(isInstalled)
                    } else {
                        result.error("INVALID_ARGUMENT", "包名不能为空", null)
                    }
                }
                "openAppInStore" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val success = AppLauncherUtil.openAppInStore(this, packageName)
                        if (success) {
                            result.success(true)
                        } else {
                            result.error("LAUNCH_FAILED", "无法打开应用商店", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "包名不能为空", null)
                    }
                }
                "getInstalledApps" -> {
                    val apps = AppLauncherUtil.getInstalledApps(this)
                    result.success(apps)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_READER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSwustMessages" -> {
                    try {
                        val limit = call.argument<Int>("limit") ?: 100
                        val messages = SmsReaderUtil.getSwustMessages(this, limit)
                        val messagesList = SmsReaderUtil.messagesToMapList(messages)
                        result.success(messagesList)
                    } catch (e: Exception) {
                        result.error("READ_ERROR", "读取短信失败：${e.message}", null)
                    }
                }
                "getRecentSwustMessages" -> {
                    try {
                        val count = call.argument<Int>("count") ?: 10
                        val messages = SmsReaderUtil.getRecentSwustMessages(this, count)
                        val messagesList = SmsReaderUtil.messagesToMapList(messages)
                        result.success(messagesList)
                    } catch (e: Exception) {
                        result.error("READ_ERROR", "读取短信失败：${e.message}", null)
                    }
                }
                "hasSwustMessages" -> {
                    try {
                        val hasMessages = SmsReaderUtil.hasMessagesWithKeyword(this, "西南科技大学")
                        result.success(hasMessages)
                    } catch (e: Exception) {
                        result.error("READ_ERROR", "检查短信失败：${e.message}", null)
                    }
                }
                "waitForSms" -> {
                    try {
                        val timeoutSeconds = call.argument<Int>("timeout") ?: 60
                        val startTime = System.currentTimeMillis()
                        
                        Thread {
                            val timeout = timeoutSeconds * 1000L
                            var foundCode: String? = null
                            
                            while (System.currentTimeMillis() - startTime < timeout && foundCode == null) {
                                Thread.sleep(1000) 
                                val messages = SmsReaderUtil.getRecentSwustMessages(this, 1)
                                if (messages.isNotEmpty()) {
                                    val message = messages[0]
                                    val messageTime = message.date
                                    
                                    if (messageTime > startTime) {
                                        val body = message.body
                                        val codePattern = Regex("验证码[：:为是]?\\s*(\\d{6})")
                                        val match = codePattern.find(body)
                                        if (match != null) {
                                            foundCode = match.groupValues[1]
                                        }
                                    }
                                }
                            }
                            
                            runOnUiThread {
                                if (foundCode != null) {
                                    result.success(foundCode)
                                } else {
                                    result.error("TIMEOUT", "等待短信超时", null)
                                }
                            }
                        }.start()
                    } catch (e: Exception) {
                        result.error("ERROR", "等待短信失败：${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        smsInterceptorMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_INTERCEPTOR_CHANNEL)
        smsInterceptorMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startInterceptor" -> {
                    SmsInterceptor.addListener(smsListener)
                    result.success("短信拦截器已启动")
                }
                "stopInterceptor" -> {
                    SmsInterceptor.removeListener(smsListener)
                    result.success("短信拦截器已停止")
                }
                "requestSmsPermission" -> {
                    if (checkSmsPermission()) {
                        result.success(true)
                    } else {
                        requestSmsPermission()
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun checkSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECEIVE_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun requestSmsPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.RECEIVE_SMS,
                Manifest.permission.READ_SMS
            ),
            SMS_PERMISSION_REQUEST_CODE
        )
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            smsInterceptorMethodChannel?.invokeMethod("onPermissionResult", granted)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        SmsInterceptor.removeListener(smsListener)
    }
}
