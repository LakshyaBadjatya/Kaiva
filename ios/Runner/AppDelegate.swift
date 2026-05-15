import Flutter
import UIKit

// ActivityKit is only available iOS 16.1+. Importing it unconditionally crashes
// on older OS versions, so we use a canImport guard via a separate file
// (LiveActivityBridge.swift) and keep this file clean of ActivityKit.

// ── Bridge constants — must match KaivaIntents.swift in widget target ───────
enum LiveActivityBridgeConstants {
    static let appGroup = "group.com.lakshya.kaiva"
    static let pendingActionKey = "kaiva.pendingPlaybackAction"
    static let darwinNotification = "com.lakshya.kaiva.playbackAction"
}

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var currentActivityBridge: Any?
    private var liveActivityChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        registerDarwinObserver()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Scene-based apps: window is owned by the scene, so set up the channel here
    // once the scene connects (called by FlutterAppDelegate's scene lifecycle).
    override func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return super.application(application, configurationForConnecting: connectingSceneSession, options: options)
    }

    // ── Darwin notification observer (App Intent → Flutter) ─────────────────

    private func registerDarwinObserver() {
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let me = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
                me.handlePendingPlaybackAction()
            },
            LiveActivityBridgeConstants.darwinNotification as CFString,
            nil,
            .deliverImmediately
        )
        handlePendingPlaybackAction()
    }

    private func handlePendingPlaybackAction() {
        guard let defaults = UserDefaults(suiteName: LiveActivityBridgeConstants.appGroup),
              let action = defaults.string(forKey: LiveActivityBridgeConstants.pendingActionKey)
        else { return }
        defaults.removeObject(forKey: LiveActivityBridgeConstants.pendingActionKey)
        defaults.synchronize()
        DispatchQueue.main.async { [weak self] in
            self?.liveActivityChannel?.invokeMethod("onAction", arguments: ["action": action])
        }
    }

    // Called from SceneDelegate once the FlutterViewController is ready
    func setupLiveActivityChannel(controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.lakshya.kaiva/live_activity",
            binaryMessenger: controller.binaryMessenger
        )
        liveActivityChannel = channel
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "start":
                if let args = call.arguments as? [String: Any] {
                    self.startLiveActivity(args: args, result: result)
                } else {
                    result(FlutterError(code: "BAD_ARGS", message: "Expected map", details: nil))
                }
            case "update":
                if let args = call.arguments as? [String: Any] {
                    self.updateLiveActivity(args: args, result: result)
                } else {
                    result(FlutterError(code: "BAD_ARGS", message: "Expected map", details: nil))
                }
            case "stop":
                self.stopLiveActivity(result: result)
            case "isSupported":
                if #available(iOS 16.2, *) {
                    result(ActivityAuthorizationInfoBridge.areActivitiesEnabled())
                } else {
                    result(false)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func startLiveActivity(args: [String: Any], result: @escaping FlutterResult) {
        if #available(iOS 16.2, *) {
            LiveActivityManager.shared.start(args: args, result: result, storage: &currentActivityBridge)
        } else {
            result(nil)
        }
    }

    func updateLiveActivity(args: [String: Any], result: @escaping FlutterResult) {
        if #available(iOS 16.2, *) {
            LiveActivityManager.shared.update(args: args, storage: currentActivityBridge, result: result)
        } else {
            result(nil)
        }
    }

    func stopLiveActivity(result: @escaping FlutterResult) {
        if #available(iOS 16.2, *) {
            LiveActivityManager.shared.stop(storage: &currentActivityBridge, result: result)
        } else {
            result(nil)
        }
    }
}
