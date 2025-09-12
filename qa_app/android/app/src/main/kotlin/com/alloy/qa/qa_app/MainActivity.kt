package com.alloy.qa.qa_app

import android.content.Context
import android.content.SharedPreferences
import androidx.preference.PreferenceManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "qa_app/cmp_mock"
    private lateinit var sharedPreferences: SharedPreferences

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Get the same SharedPreferences instance that the SDK uses
        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setValue" -> {
                    try {
                        val key = call.argument<String>("key")
                        val value = call.argument<Any>("value")
                        
                        if (key == null) {
                            result.error("INVALID_ARGUMENT", "Key argument cannot be null", null)
                            return@setMethodCallHandler
                        }
                        
                        val editor = sharedPreferences.edit()
                        when (value) {
                            is String -> editor.putString(key, value)
                            is Boolean -> editor.putBoolean(key, value)
                            is Int -> editor.putInt(key, value)
                            is Long -> editor.putLong(key, value)
                            is Float -> editor.putFloat(key, value)
                            null -> editor.remove(key)
                            else -> {
                                result.error("INVALID_TYPE", "Unsupported value type: ${value::class.java.simpleName}", null)
                                return@setMethodCallHandler
                            }
                        }
                        editor.apply()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("NATIVE_ERROR", "Failed to set value in SharedPreferences", e.toString())
                    }
                }
                "getValue" -> {
                    try {
                        val key = call.argument<String>("key")
                        if (key == null) {
                            result.error("INVALID_ARGUMENT", "Key argument cannot be null", null)
                            return@setMethodCallHandler
                        }
                        val value = sharedPreferences.all[key]
                        result.success(value)
                    } catch (e: Exception) {
                        result.error("NATIVE_ERROR", "Failed to retrieve value from SharedPreferences", e.toString())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
