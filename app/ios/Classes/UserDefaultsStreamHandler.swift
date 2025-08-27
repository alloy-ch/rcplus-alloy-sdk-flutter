import Foundation
import Flutter

/**
 * StreamHandler for UserDefaults.
 */
internal class UserDefaultsStreamHandler: NSObject, FlutterStreamHandler {
    
    private enum Key {
        static let prefix: String = "IABTCF"
    }
    
    private var eventSink: FlutterEventSink?
    private var lastKnownValues = [String: Any]()
    
    // Add thread safety
    private let accessQueue = DispatchQueue(label: "userdefaults.handler", qos: .utility)

    /**
     * Called when Flutter starts listening.
     */
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        accessQueue.sync {
            self.eventSink = events
        }
        
        accessQueue.async { [weak self] in
            guard let self = self else { return }
            
            let userDefaults: UserDefaults = .standard

            // 1. Send all initial values that already exist, filtered to IABTCF keys only.
            let allKeys = userDefaults.dictionaryRepresentation().keys
            let iabtcfKeys: [String] = self.filterIABTCFKeys(allKeys)
            for key in iabtcfKeys {
                let value = userDefaults.object(forKey: key)
                self.lastKnownValues[key] = value
                if let serializedValue = UserDefaultsSerializer.serializeValue(value) {
                    DispatchQueue.main.async {
                        events(["key": key, "value": serializedValue])
                    }
                } else {
                    print("Skipping UserDefaults key '\(key)' - value cannot be serialized for Flutter")
                }
            }
        }
        
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
        
        accessQueue.sync {
            eventSink = nil
        }
        return nil
    }

    /// Called by NotificationCenter when UserDefaults changes.
    @objc private func userDefaultsDidChange(notification: Notification) {
        guard let userDefaults = notification.object as? UserDefaults else { return }

        accessQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check all IABTCF keys for changes, as the notification doesn't specify which one changed.
            let allKeys: Set = Set(userDefaults.dictionaryRepresentation().keys)
            let newIABTCFKeys: [String] = self.filterIABTCFKeys(allKeys)
            let allRelevantKeys: Set<String> = Set(newIABTCFKeys).union(Set(self.lastKnownValues.keys))

            for key in allRelevantKeys {
                let newValue: Any? = userDefaults.object(forKey: key)
                let oldValue: Any? = self.lastKnownValues[key]

                if !self.areEqual(oldValue, newValue) {
                    self.lastKnownValues[key] = newValue
                    
                    // Ensure Flutter channel calls are made on the main thread
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, 
                              let sink = self.eventSink,
                              let serializedValue = UserDefaultsSerializer.serializeValue(newValue) else { 
                            return 
                        }
                        sink(["key": key, "value": serializedValue])
                    }
                }
            }
        }
    }

    /// Helper to compare two optional `Any` values.
    private func areEqual(_ a: Any?, _ b: Any?) -> Bool {
        if a == nil && b == nil { return true }
        guard let a = a as? NSObject, let b = b as? NSObject else { return false }
        return a.isEqual(b)
    }

    /// Filters keys to only include those with IABTCF prefix
    private func filterIABTCFKeys<T: Collection>(_ keys: T) -> [String] where T.Element == String {
        return keys.filter { $0.hasPrefix(Key.prefix) }
    }
}
