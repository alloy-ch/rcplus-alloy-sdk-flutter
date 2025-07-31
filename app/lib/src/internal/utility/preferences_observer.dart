import 'dart:async';
import 'package:flutter/services.dart';

/// Provides a mechanism to observe and fetch values from native key-value stores.
///
/// This class uses:
/// - An `EventChannel` to stream changes from UserDefaults (iOS) and SharedPreferences (Android).
/// - A `MethodChannel` to fetch a single value on demand.
class PreferencesObserver {
  // Channel for receiving a stream of updates.
  static const EventChannel _eventChannel =
      EventChannel('com.alloy.alloy_sdk/stream');

  // Channel for one-time method calls (e.g., getting a single value).
  static const MethodChannel _methodChannel =
      MethodChannel('com.alloy.alloy_sdk/methods');

  static Stream<Map<dynamic, dynamic>>? _broadcastStream;

  /// Returns a broadcast stream that emits all key-value change events.
  static Stream<Map<dynamic, dynamic>> get _stream {
    _broadcastStream ??= _eventChannel.receiveBroadcastStream().cast<Map<dynamic, dynamic>>();
    return _broadcastStream!;
  }

  /// Observes a specific [key] for changes in the native key-value store.
  ///
  /// The stream will first emit the current value of the key (if it exists)
  /// and then any subsequent changes. If the value is removed, `null` is emitted.
  ///
  /// @param key The key to observe.
  /// @return A `Stream<dynamic>` that emits the new value whenever it changes.
  static Stream<dynamic> observe(String key) {
    return _stream
        .where((event) => event['key'] == key)
        .map((event) => event['value']);
  }

  /// Fetches the current value for a given [key] from the native side.
  ///
  /// This is useful for getting a value once, without setting up a listener stream.
  ///
  /// Example:
  /// ```dart
  /// final username = await UserDefaultsObserver.getValue('username');
  /// ```
  /// @param key The key of the value to fetch.
  /// @return A `Future<dynamic>` that completes with the value, or `null` if not found.
  static Future<dynamic> getValue(String key) async {
    try {
      return await _methodChannel.invokeMethod('getValue', {'key': key});
    } on PlatformException catch (e) {
      return null;
    }
  }
}