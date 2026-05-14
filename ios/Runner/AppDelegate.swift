import ActivityKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    // Holds the currently running Live Activity so we can update / end it
    private var currentActivity: Activity<KaivaActivityAttributes>?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        setupLiveActivityChannel(binaryMessenger: engineBridge.binaryMessenger)
    }

    // ── Flutter ↔ Native channel ─────────────────────────────────────────────

    private func setupLiveActivityChannel(binaryMessenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "com.lakshya.kaiva/live_activity",
            binaryMessenger: binaryMessenger
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
                result(ActivityAuthorizationInfo().areActivitiesEnabled)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // ── Activity lifecycle ───────────────────────────────────────────────────

    private func startActivity(args: [String: Any], result: FlutterResult) {
        guard #available(iOS 16.1, *) else { result(nil); return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { result(nil); return }

        // End any previous activity first
        Task {
            await self.endCurrentActivityImmediately()

            let state = self.makeContentState(from: args)
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

    private func updateActivity(args: [String: Any], result: FlutterResult) {
        guard #available(iOS 16.1, *) else { result(nil); return }
        guard let activity = currentActivity else { result(nil); return }

        let state = makeContentState(from: args)
        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.update(content)
            result(nil)
        }
    }

    private func stopActivity(result: FlutterResult) {
        guard #available(iOS 16.1, *) else { result(nil); return }
        Task {
            await self.endCurrentActivityImmediately()
            result(nil)
        }
    }

    @available(iOS 16.1, *)
    private func endCurrentActivityImmediately() async {
        guard let activity = currentActivity else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private func makeContentState(from args: [String: Any]) -> KaivaActivityAttributes.ContentState {
        KaivaActivityAttributes.ContentState(
            title: args["title"] as? String ?? "",
            artist: args["artist"] as? String ?? "",
            albumArt: args["albumArt"] as? String ?? "",
            isPlaying: args["isPlaying"] as? Bool ?? false,
            elapsedSeconds: args["elapsedSeconds"] as? Double ?? 0,
            durationSeconds: args["durationSeconds"] as? Double ?? 0
        )
    }
}
