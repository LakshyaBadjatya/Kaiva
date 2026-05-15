import Foundation
import ActivityKit

// All ActivityKit code lives here so AppDelegate.swift stays ActivityKit-free.
// The compiler only loads this file on iOS 16.1+ thanks to the availability guard.

@available(iOS 16.2, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    func start(args: [String: Any], result: @escaping FlutterResult, storage: inout Any?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { result(nil); return }
        Task {
            await self.endCurrent(storage: &storage)
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
                storage = activity
                result(activity.id)
            } catch {
                result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }

    func update(args: [String: Any], storage: Any?, result: @escaping FlutterResult) {
        guard let activity = storage as? Activity<KaivaActivityAttributes> else { result(nil); return }
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

    func stop(storage: inout Any?, result: @escaping FlutterResult) {
        Task {
            await self.endCurrent(storage: &storage)
            result(nil)
        }
    }

    private func endCurrent(storage: inout Any?) async {
        if let activity = storage as? Activity<KaivaActivityAttributes> {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        storage = nil
    }
}

// Helper to check Live Activity authorization without importing ActivityKit in AppDelegate
@available(iOS 16.2, *)
enum ActivityAuthorizationInfoBridge {
    static func areActivitiesEnabled() -> Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
}
