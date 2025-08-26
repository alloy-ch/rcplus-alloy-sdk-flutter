import Flutter
import UIKit

public class PreferencesObserverPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance: PreferencesObserverPlugin = PreferencesObserverPlugin()
        
        // Setup Method Channel for fetching values on-demand
        let methodChannel: FlutterMethodChannel = FlutterMethodChannel(
            name: "com.alloy.alloy_sdk/methods",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        
        // Setup Event Channel for streaming all updates
        let eventChannel: FlutterEventChannel = FlutterEventChannel(
            name: "com.alloy.alloy_sdk/stream",
            binaryMessenger: registrar.messenger()
        )
        let streamHandler: UserDefaultsStreamHandler = UserDefaultsStreamHandler()
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
            let value: Any? = UserDefaults.standard.object(forKey: key)
            let serializedValue: Any? = UserDefaultsSerializer.serializeValue(value)
            result(serializedValue)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}
