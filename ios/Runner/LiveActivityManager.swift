import Foundation
import ActivityKit

// Mirror of KaivaActivityAttributes from the widget extension — inlined here
// so the Runner target doesn't need to import the widget target.
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

// All ActivityKit code lives here so AppDelegate.swift stays ActivityKit-free.

@available(iOS 16.2, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    // Store the activity inside the manager — avoids inout + escaping closure issues.
    private var currentActivity: Activity<KaivaActivityAttributes>?

    func start(args: [String: Any], result: @escaping FlutterResult) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { result(nil); return }
        Task {
            await self.endCurrent()
            let state = KaivaActivityAttributes.ContentState(
                title: args["title"] as? String ?? "",
                artist: args["artist"] as? String ?? "",
                albumArt: args["albumArt"] as? String ?? "",
                isPlaying: args["isPlaying"] as? Bool ?? false,
                elapsedSeconds: args["elapsedSeconds"] as? Double ?? 0,
                durationSeconds: args["durationSeconds"] as? Double ?? 0
            )
            let content = ActivityContent(state: state, staleDate: nil)
            do {
                let activity = try Activity.request(
                    attributes: KaivaActivityAttributes(),
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

    func update(args: [String: Any], result: @escaping FlutterResult) {
        guard let activity = currentActivity else { result(nil); return }
        let state = KaivaActivityAttributes.ContentState(
            title: args["title"] as? String ?? "",
            artist: args["artist"] as? String ?? "",
            albumArt: args["albumArt"] as? String ?? "",
            isPlaying: args["isPlaying"] as? Bool ?? false,
            elapsedSeconds: args["elapsedSeconds"] as? Double ?? 0,
            durationSeconds: args["durationSeconds"] as? Double ?? 0
        )
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
            result(nil)
        }
    }

    func stop(result: @escaping FlutterResult) {
        Task {
            await self.endCurrent()
            result(nil)
        }
    }

    private func endCurrent() async {
        if let activity = currentActivity {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}

@available(iOS 16.2, *)
enum ActivityAuthorizationInfoBridge {
    static func areActivitiesEnabled() -> Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
}
