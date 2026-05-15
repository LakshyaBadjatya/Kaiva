import ActivityKit
import Flutter
import UIKit

// Mirror of the type defined in KaivaWidgetExtension/KaivaActivityAttributes.swift.
// We inline it here so the Runner target does not need to import the widget target.
@available(iOS 16.1, *)
public struct KaivaActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String
        public var artist: String
        public var albumArt: String
        public var isPlaying: Bool
        public var elapsedSeconds: Double
        public var durationSeconds: Double
    }
    public var appName: String = "Kaiva"
}

@main
@objc class AppDelegate: FlutterAppDelegate {

    // Live Activity is iOS 16.1+ only. The property must be wrapped in @available
    // (we stash it as Any? to avoid pulling the type into the class declaration
    // and forcing every method to be iOS-16.1-gated).
    private var currentActivity: Any?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        setupLiveActivityChannel()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ── Flutter ↔ Native channel ─────────────────────────────────────────────

    private func setupLiveActivityChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        let channel = FlutterMethodChannel(
            name: "com.lakshya.kaiva/live_activity",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "start":
                if let args = call.arguments as? [String: Any] {
                    self.startActivity(args: args, result: result)
                } else {
                    result(FlutterError(code: "BAD_ARGS", message: "Expected map", details: nil))
                }
            case "update":
                if let args = call.arguments as? [String: Any] {
                    self.updateActivity(args: args, result: result)
                } else {
                    result(FlutterError(code: "BAD_ARGS", message: "Expected map", details: nil))
                }
            case "stop":
                self.stopActivity(result: result)
            case "isSupported":
                if #available(iOS 16.1, *) {
                    result(ActivityAuthorizationInfo().areActivitiesEnabled)
                } else {
                    result(false)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // ── Activity lifecycle ───────────────────────────────────────────────────

    private func startActivity(args: [String: Any], result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(nil); return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { result(nil); return }

        Task {
            await self.endCurrentActivityImmediately()

            let state = KaivaActivityAttributes.ContentState(
                title: args["title"] as? String ?? "",
                artist: args["artist"] as? String ?? "",
                albumArt: args["albumArt"] as? String ?? "",
                isPlaying: args["isPlaying"] as? Bool ?? false,
                elapsedSeconds: args["elapsedSeconds"] as? Double ?? 0,
                durationSeconds: args["durationSeconds"] as? Double ?? 0
            )
            let attrs = KaivaActivityAttributes()
            let content = ActivityContent(state: state, staleDate: nil)

            do {
                let activity = try Activity.request(
                    attributes: attrs,
                    content: content,
                    pushType: nil
                )
                self.currentActivity = activity
                result(activity.id)
            } catch {
                result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }

    private func updateActivity(args: [String: Any], result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(nil); return }
        guard let activity = currentActivity as? Activity<KaivaActivityAttributes> else {
            result(nil); return
        }

        let state = KaivaActivityAttributes.ContentState(
            title: args["title"] as? String ?? "",
            artist: args["artist"] as? String ?? "",
            albumArt: args["albumArt"] as? String ?? "",
            isPlaying: args["isPlaying"] as? Bool ?? false,
            elapsedSeconds: args["elapsedSeconds"] as? Double ?? 0,
            durationSeconds: args["durationSeconds"] as? Double ?? 0
        )
        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.update(content)
            result(nil)
        }
    }

    private func stopActivity(result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(nil); return }
        Task {
            await self.endCurrentActivityImmediately()
            result(nil)
        }
    }

    @available(iOS 16.1, *)
    private func endCurrentActivityImmediately() async {
        guard let activity = currentActivity as? Activity<KaivaActivityAttributes> else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
    }
}
