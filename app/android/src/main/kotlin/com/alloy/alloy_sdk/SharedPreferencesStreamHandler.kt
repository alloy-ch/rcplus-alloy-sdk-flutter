package com.alloy.alloy_sdk

import android.os.Handler
import android.os.Looper
import android.content.SharedPreferences
import io.flutter.plugin.common.EventChannel

internal class SharedPreferencesStreamHandler(
    private val sharedPreferences: SharedPreferences
) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private var listener: SharedPreferences.OnSharedPreferenceChangeListener? = null
    private val handler = Handler(Looper.getMainLooper())
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        val entries = sharedPreferences.all.filterKeys { it.startsWith(PreferencesObserverPlugin.KEY_PREFIX) }
        for ((key, value) in entries) {
            val serialized = PreferencesObserverPlugin.serializeValue(value)
            handler.post { eventSink?.success(mapOf("key" to key, "value" to serialized)) }
        }

        // 2. Register a listener for any subsequent changes.
        listener = SharedPreferences.OnSharedPreferenceChangeListener { prefs, key ->
            val k = key ?: return@OnSharedPreferenceChangeListener
            if (!k.startsWith(PreferencesObserverPlugin.KEY_PREFIX)) return@OnSharedPreferenceChangeListener
            val value = prefs.all[k]
            val serialized = PreferencesObserverPlugin.serializeValue(value)
            handler.post { eventSink?.success(mapOf("key" to k, "value" to serialized)) }
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