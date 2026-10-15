import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let iconChannel = FlutterMethodChannel(
      name: "remindya/app_icon",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    iconChannel.setMethodCallHandler { call, result in
      guard call.method == "setIcon",
        let args = call.arguments as? [String: Any],
        let name = args["name"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      // Alternate icon sets in Assets.xcassets; nil is the primary (happy) icon.
      let alternates: [String: String?] = [
        "happy": nil, "sad": "AppIcon-Sad", "feral": "AppIcon-Feral",
      ]
      guard let target = alternates[name] else {
        result(FlutterError(code: "bad_icon", message: "Unknown icon: \(name)", details: nil))
        return
      }
      let app = UIApplication.shared
      guard app.supportsAlternateIcons, app.alternateIconName != target else {
        result(nil)
        return
      }
      app.setAlternateIconName(target) { error in
        if let error = error {
          result(FlutterError(code: "set_failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }
}
