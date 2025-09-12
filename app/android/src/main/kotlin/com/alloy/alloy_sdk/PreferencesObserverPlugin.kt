package com.alloy.alloy_sdk

import android.content.Context
import android.content.SharedPreferences
import androidx.preference.PreferenceManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PreferencesObserverPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var sharedPreferences: SharedPreferences

    companion object {

        const val KEY_PREFIX: String = "IABTCF"
        fun serializeValue(value: Any?): Any? {
            return when (value) {
                null -> null
                is Float -> value.toDouble()
                is Set<*> -> value.filterIsInstance<String>()
                is Boolean, is Int, is Long, is Double, is String -> value
                else -> value.toString()
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        // Use default shared preferences to access keys set by other SDKs like IABTCF_TCString
        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context)

        // Setup Method Channel for fetching values on-demand
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.alloy.alloy_sdk/methods")
        methodChannel.setMethodCallHandler(this)

        // Setup Event Channel for streaming all updates
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.alloy.alloy_sdk/stream")
        val streamHandler = SharedPreferencesStreamHandler(sharedPreferences)
        eventChannel.setStreamHandler(streamHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "getValue") {
            try {
                val key = call.argument<String>("key")
                if (key == null) {
                    result.error("INVALID_ARGUMENT", "Key argument cannot be null", null)
                    return
                }
                // Retrieve the value from SharedPreferences for the requested key.
                val rawValue = sharedPreferences.all[key]
                val value = serializeValue(rawValue)
                result.success(value)
            } catch (e: Exception) {
                result.error("NATIVE_ERROR", "Failed to retrieve value from SharedPreferences", e.toString())
            }
        } else {
            result.notImplemented()
        }
    }
}