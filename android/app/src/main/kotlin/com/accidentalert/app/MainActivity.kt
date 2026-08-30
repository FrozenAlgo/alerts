package com.accidentalert.app

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.SmsManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val number = call.argument<String>("number")
                        val message = call.argument<String>("message")
                        if (number.isNullOrBlank() || message.isNullOrBlank()) {
                            result.error("INVALID", "Number and message required", null)
                            return@setMethodCallHandler
                        }
                        if (ContextCompat.checkSelfPermission(
                                this,
                                Manifest.permission.SEND_SMS,
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error("PERMISSION_DENIED", "SEND_SMS not granted", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val smsManager = SmsManager.getDefault()
                            val parts = smsManager.divideMessage(message)
                            if (parts.size <= 1) {
                                smsManager.sendTextMessage(number, null, message, null, null)
                            } else {
                                smsManager.sendMultipartTextMessage(
                                    number,
                                    null,
                                    parts,
                                    null,
                                    null,
                                )
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SEND_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        private const val SMS_CHANNEL = "com.accidentalert.app/sms"
    }
}
