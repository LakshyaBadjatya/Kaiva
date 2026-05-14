import ActivityKit
import Foundation

// Shared between the app and the widget extension.
// Must be identical in both targets.
public struct KaivaActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String
        public var artist: String
        public var albumArt: String   // URL string — widget fetches async
        public var isPlaying: Bool
        public var elapsedSeconds: Double
        public var durationSeconds: Double

        public init(
            title: String,
            artist: String,
            albumArt: String,
            isPlaying: Bool,
            elapsedSeconds: Double,
            durationSeconds: Double
        ) {
            self.title = title
            self.artist = artist
            self.albumArt = albumArt
            self.isPlaying = isPlaying
            self.elapsedSeconds = elapsedSeconds
            self.durationSeconds = durationSeconds
        }
    }

    // Static data that doesn't change for the lifetime of an activity
    public var appName: String

    public init(appName: String = "Kaiva") {
        self.appName = appName
    }
}
