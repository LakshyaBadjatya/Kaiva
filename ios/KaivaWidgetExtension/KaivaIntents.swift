import AppIntents
import Foundation

// ── Shared constants ────────────────────────────────────────────────────────

enum KaivaIntentBridge {
    static let appGroup = "group.com.lakshya.kaiva"
    static let pendingActionKey = "kaiva.pendingPlaybackAction"
    static let actionTimestampKey = "kaiva.pendingPlaybackActionTimestamp"
    static let darwinNotification = "com.lakshya.kaiva.playbackAction"

    static func postAction(_ action: String) {
        if let defaults = UserDefaults(suiteName: appGroup) {
            defaults.set(action, forKey: pendingActionKey)
            defaults.set(Date().timeIntervalSince1970, forKey: actionTimestampKey)
            defaults.synchronize()
        }
        // Darwin notifications cross process boundaries — main app observes this.
        let name = darwinNotification as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name),
            nil,
            nil,
            true
        )
    }
}

// ── App Intents (iOS 17+) ───────────────────────────────────────────────────

@available(iOS 17.0, *)
struct KaivaPlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Play / Pause"
    static var description = IntentDescription("Toggle playback in Kaiva.")

    // openAppWhenRun=false keeps the system in the Live Activity context.
    // The action is delivered via Darwin notification + shared UserDefaults.
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        KaivaIntentBridge.postAction("play_pause")
        return .result()
    }
}

@available(iOS 17.0, *)
struct KaivaNextIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"
    static var description = IntentDescription("Skip to the next song in Kaiva.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        KaivaIntentBridge.postAction("next")
        return .result()
    }
}

@available(iOS 17.0, *)
struct KaivaPreviousIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"
    static var description = IntentDescription("Skip to the previous song in Kaiva.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        KaivaIntentBridge.postAction("previous")
        return .result()
    }
}
