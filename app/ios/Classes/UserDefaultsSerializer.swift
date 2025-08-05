import Foundation

internal class UserDefaultsSerializer {

    static func serializeValue(_ value: Any?) -> Any? {
        guard let value = value else { return nil }
        
        switch value {
        case let data as Data:
            return data.base64EncodedString()
        case let date as Date:
            return date.timeIntervalSince1970 * 1000
        case let url as URL:
            return url.absoluteString
        case is NSString, is NSNumber, is Bool:
            return value
        case is NSNull:
            return nil
        case let array as NSArray:
            return array.compactMap { serializeValue($0) }
        case let dict as NSDictionary:
            var serializedDict: [String: Any] = [:]
            for (key, val) in dict {
                if let stringKey = key as? String {
                    if let serializedVal = serializeValue(val) {
                        serializedDict[stringKey] = serializedVal
                    }
                }
            }
            return serializedDict
        default:
            let stringValue = String(describing: value)
            if stringValue.isEmpty || stringValue.hasPrefix("<") {
                return nil
            }
            return stringValue
        }
    }
}
