package com.alloy.alloy_sdk

import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
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
                val value = sharedPreferences.all[key]
                result.success(value)
            } catch (e: Exception) {
                result.error("NATIVE_ERROR", "Failed to retrieve value from SharedPreferences", e.toString())
            }
        } else {
            result.notImplemented()
        }
    }
}

private class SharedPreferencesStreamHandler(
    private val sharedPreferences: SharedPreferences
) : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    private var listener: SharedPreferences.OnSharedPreferenceChangeListener? = null

    private val handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events

        // 1. Send all initial values that already exist.
        for ((key, value) in sharedPreferences.all) {
            handler.post { eventSink?.success(mapOf("key" to key, "value" to value)) }
        }

        // 2. Register a listener for any subsequent changes.
        listener = SharedPreferences.OnSharedPreferenceChangeListener { prefs, key ->
            val value = prefs.all[key] // This will be null if the key was removed.
            handler.post { eventSink?.success(mapOf("key" to key, "value" to value)) }
        }
        sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
    }

    override fun onCancel(arguments: Any?) {
        if (listener != null) {
            sharedPreferences.unregisterOnSharedPreferenceChangeListener(listener)
        }
        eventSink = null
        listener = null
    }
}
