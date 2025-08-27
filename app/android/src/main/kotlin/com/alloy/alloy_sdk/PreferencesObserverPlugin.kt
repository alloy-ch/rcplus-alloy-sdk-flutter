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
    private var streamHandler: SharedPreferencesStreamHandler? = null

    companion object {
        private const val IABTCF_PREFIX = "IABTCF"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context)

        // Setup Method Channel for fetching values on-demand
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.alloy.alloy_sdk/methods")
        methodChannel.setMethodCallHandler(this)

        // Setup Event Channel for streaming all updates
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.alloy.alloy_sdk/stream")
        streamHandler = SharedPreferencesStreamHandler(sharedPreferences)
        eventChannel.setStreamHandler(streamHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        // Ensure proper cleanup
        streamHandler?.cleanup()
        eventChannel.setStreamHandler(null)
        streamHandler = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "getValue") {
            try {
                val key = call.argument<String>("key")
                if (key == null) {
                    result.error("INVALID_ARGUMENT", "Key argument cannot be null", null)
                    return
                }
                // Only allow access to IABTCF keys for security
                if (!key.startsWith(IABTCF_PREFIX)) {
                    result.error("ACCESS_DENIED", "Only IABTCF keys are accessible", null)
                    return
                }
                
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

    @Volatile
    private var eventSink: EventChannel.EventSink? = null
    private var listener: SharedPreferences.OnSharedPreferenceChangeListener? = null
    private val handler = Handler(Looper.getMainLooper())
    private val lock = Any()

    companion object {
        private const val IABTCF_PREFIX = "IABTCF"
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        synchronized(lock) {
            this.eventSink = events
        }

        try {
            // 1. Send all initial IABTCF values only
            val allPrefs = HashMap(sharedPreferences.all)
            for ((key, value) in allPrefs) {
                if (key.startsWith(IABTCF_PREFIX)) {
                    synchronized(lock) {
                        eventSink?.success(mapOf("key" to key, "value" to value))
                    }
                }
            }

            // 2. Register listener for changes
            listener = SharedPreferences.OnSharedPreferenceChangeListener { prefs, key ->
                // Only process IABTCF keys
                if (key?.startsWith(IABTCF_PREFIX) == true) {
                    try {
                        val value = prefs.all[key]
                        synchronized(lock) {
                            eventSink?.success(mapOf("key" to key, "value" to value))
                        }
                    } catch (e: Exception) {
                        synchronized(lock) {
                            eventSink?.error("STREAM_ERROR", "Failed to process preference change", e.toString())
                        }
                    }
                }
            }
            sharedPreferences.registerOnSharedPreferenceChangeListener(listener)
        } catch (e: Exception) {
            synchronized(lock) {
                eventSink?.error("INITIALIZATION_ERROR", "Failed to initialize stream", e.toString())
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        cleanup()
    }

    fun cleanup() {
        synchronized(lock) {
            try {
                listener?.let {
                    sharedPreferences.unregisterOnSharedPreferenceChangeListener(it)
                }
            } catch (e: Exception) {
                // Log error but don't crash
            } finally {
                eventSink = null
                listener = null
            }
        }
    }
}
