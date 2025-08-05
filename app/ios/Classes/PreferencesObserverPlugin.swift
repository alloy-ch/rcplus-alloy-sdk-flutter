import Flutter
import UIKit

public class PreferencesObserverPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = PreferencesObserverPlugin()

    // Setup Method Channel for fetching values on-demand
    let methodChannel = FlutterMethodChannel(name: "com.alloy.alloy_sdk/methods", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    // Setup Event Channel for streaming all updates
    let eventChannel = FlutterEventChannel(name: "com.alloy.alloy_sdk/stream", binaryMessenger: registrar.messenger())
    let streamHandler = UserDefaultsStreamHandler()
    eventChannel.setStreamHandler(streamHandler)
  }

  /**
   * Handles incoming method calls from Dart.
   */
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getValue" {
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Key argument is missing or invalid", details: nil))
        return
      }
      // Retrieve the value from standard UserDefaults for the requested key.
      let value = UserDefaults.standard.object(forKey: key)
      let serializedValue = serializeValue(value)
      result(serializedValue)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
  
  /// Serializes a value to ensure it's compatible with Flutter's method channel.
  private func serializeValue(_ value: Any?) -> Any? {
      guard let value = value else { return nil }
      
      // Flutter method channels support: NSNull, NSNumber, NSString, NSArray, NSDictionary, NSData
      // Convert problematic types to Flutter-compatible ones
      switch value {
      case let data as Data:
          // Convert NSData to base64 string for Flutter compatibility
          return data.base64EncodedString()
      case let date as Date:
          // Convert Date to timestamp (milliseconds since epoch)
          return date.timeIntervalSince1970 * 1000
      case let url as URL:
          // Convert URL to string
          return url.absoluteString
      case is NSString, is NSNumber, is NSArray, is NSDictionary, is NSNull:
          // These types are already Flutter-compatible
          return value
      default:
          // For any other type, convert to string representation
          return String(describing: value)
      }
  }
}

/**
 * StreamHandler for UserDefaults.
 */
private class UserDefaultsStreamHandler: NSObject, FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?

    private var lastKnownValues = [String: Any?]()

    /**
     * Called when Flutter starts listening.
     */
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        let userDefaults = UserDefaults.standard

        // 1. Send all initial values that already exist.
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            let value = userDefaults.object(forKey: key)
            lastKnownValues[key] = value // Cache the initial value
            
            // Serialize the value to ensure it's Flutter-compatible
            let serializedValue = serializeValue(value)
            events(["key": key, "value": serializedValue]) // Send to Flutter
        }

        // 2. Register for notifications for any subsequent changes.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        return nil
    }

    /**
     * Called when Flutter stops listening.
     */
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }

    /// Called by NotificationCenter when UserDefaults changes.
    @objc private func userDefaultsDidChange(notification: Notification) {
        guard let userDefaults = notification.object as? UserDefaults else { return }

        // Check all keys for changes, as the notification doesn't specify which one changed.
        let newKeys = Set(userDefaults.dictionaryRepresentation().keys)
        let allRelevantKeys = newKeys.union(lastKnownValues.keys)

        for key in allRelevantKeys {
            let newValue = userDefaults.object(forKey: key)
            let oldValue = lastKnownValues[key]

            if !areEqual(oldValue, newValue) {
                // Ensure Flutter channel calls are made on the main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, let sink = self.eventSink else { return }
                    
                    // Serialize the value to ensure it's Flutter-compatible
                    let serializedValue = self.serializeValue(newValue)
                    sink(["key": key, "value": serializedValue])
                }
                lastKnownValues[key] = newValue // Update cache
            }
        }
    }

    /// Helper to compare two optional `Any` values.
    private func areEqual(_ a: Any?, _ b: Any?) -> Bool {
        if a == nil && b == nil { return true }
        guard let a = a as? NSObject, let b = b as? NSObject else { return false }
        return a.isEqual(b)
    }
    
    /// Serializes a value to ensure it's compatible with Flutter's method channel.
    private func serializeValue(_ value: Any?) -> Any? {
        guard let value = value else { return nil }
        
        // Flutter method channels support: NSNull, NSNumber, NSString, NSArray, NSDictionary, NSData
        // Convert problematic types to Flutter-compatible ones
        switch value {
        case let data as Data:
            // Convert NSData to base64 string for Flutter compatibility
            return data.base64EncodedString()
        case let date as Date:
            // Convert Date to timestamp (milliseconds since epoch)
            return date.timeIntervalSince1970 * 1000
        case let url as URL:
            // Convert URL to string
            return url.absoluteString
        case is NSString, is NSNumber, is NSArray, is NSDictionary, is NSNull:
            // These types are already Flutter-compatible
            return value
        default:
            // For any other type, convert to string representation
            return String(describing: value)
        }
    }
}
