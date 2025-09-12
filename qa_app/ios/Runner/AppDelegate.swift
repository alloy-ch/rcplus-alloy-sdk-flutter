import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let cmpMockChannel = FlutterMethodChannel(name: "qa_app/cmp_mock",
                                              binaryMessenger: controller.binaryMessenger)
    
    cmpMockChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      switch call.method {
      case "setValue":
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Key argument is missing or invalid", details: nil))
          return
        }
        
        let value = args["value"]
        print("CMP Mock setValue: key=\(key), value=\(String(describing: value)), type=\(type(of: value))")
        
        if value == nil || (value is NSNull) {
          print("CMP Mock: Removing value for key: \(key)")
          UserDefaults.standard.removeObject(forKey: key)
        } else {
          print("CMP Mock: Setting value for key: \(key)")
          UserDefaults.standard.set(value, forKey: key)
        }
        UserDefaults.standard.synchronize()
        result(nil)
        
      case "getValue":
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Key argument is missing or invalid", details: nil))
          return
        }
        
        let value = UserDefaults.standard.object(forKey: key)
        result(value)
        
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
