import Foundation

/// A thread-safe wrapper around a Swift Dictionary.
class ThreadSafeDictionary<Key: Hashable, Value> {

    private var dictionary: [Key: Value] = [:]

    // A concurrent queue allows for multiple simultaneous reads.
    private let queue: DispatchQueue = DispatchQueue(
        label: "ch.alloy.accessQueue",
        attributes: .concurrent
    )

    /// Safely gets or sets the value for the given key.
    subscript(key: Key) -> Value? {
        get {
            return queue.sync {
                self.dictionary[key]
            }
        }
        set(newValue) {
            queue.async(flags: .barrier) {
                if let newValue {
                    self.dictionary[key] = newValue
                } else {
                    self.dictionary.removeValue(forKey: key)
                }
            }
        }
    }
    
    var values: [Value] {
        return queue.sync {
            Array(self.dictionary.values)
        }
    }

    var keys: [Key] {
        return queue.sync {
            Array(self.dictionary.keys)
        }
    }
}
