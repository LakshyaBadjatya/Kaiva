import ActivityKit
import SwiftUI
import WidgetKit

// ── Cached async album art ──────────────────────────────────────────────────

struct AlbumArtView: View {
    let urlString: String
    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color(red: 0.09, green: 0.09, blue: 0.14)
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.49, green: 0.43, blue: 0.94))
                }
            }
        }
        .onAppear { loadImage() }
        .onChange(of: urlString) { _ in loadImage() }
    }

    private func loadImage() {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
                DispatchQueue.main.async { image = img }
            }
        }.resume()
    }
}

// ── Progress bar ────────────────────────────────────────────────────────────

struct ProgressBar: View {
    let elapsed: Double
    let duration: Double

    var progress: CGFloat {
        duration > 0 ? CGFloat(min(elapsed / duration, 1.0)) : 0
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 3)
                Capsule()
                    .fill(Color(red: 0.94, green: 0.62, blue: 0.15))
                    .frame(width: geo.size.width * progress, height: 3)
            }
        }
        .frame(height: 3)
    }
}

// ── Lock Screen / Notification Banner view ──────────────────────────────────

struct KaivaLockScreenView: View {
    let state: KaivaActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            // Album art
            AlbumArtView(urlString: state.albumArt)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Song info + progress
            VStack(alignment: .leading, spacing: 4) {
                Text(state.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(state.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
                ProgressBar(elapsed: state.elapsedSeconds, duration: state.durationSeconds)
                    .frame(height: 3)
            }

            Spacer()

            // Play / Pause indicator
            Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.09, green: 0.09, blue: 0.14))
    }
}

// ── Dynamic Island — Compact leading ────────────────────────────────────────

struct KaivaCompactLeadingView: View {
    let state: KaivaActivityAttributes.ContentState

    var body: some View {
        AlbumArtView(urlString: state.albumArt)
            .frame(width: 28, height: 28)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// ── Dynamic Island — Compact trailing ───────────────────────────────────────

struct KaivaCompactTrailingView: View {
    let state: KaivaActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(red: 0.94, green: 0.62, blue: 0.15))
        }
    }
}

// ── Dynamic Island — Minimal ─────────────────────────────────────────────────

struct KaivaMinimalView: View {
    let state: KaivaActivityAttributes.ContentState

    var body: some View {
        AlbumArtView(urlString: state.albumArt)
            .frame(width: 22, height: 22)
            .clipShape(Circle())
    }
}

// ── Dynamic Island — Expanded ────────────────────────────────────────────────

struct KaivaExpandedView: View {
    let state: KaivaActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                AlbumArtView(urlString: state.albumArt)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(state.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(state.artist)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 0.94, green: 0.62, blue: 0.15))
            }

            ProgressBar(elapsed: state.elapsedSeconds, duration: state.durationSeconds)
                .frame(height: 3)
                .padding(.horizontal, 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// ── Widget configuration ─────────────────────────────────────────────────────

struct KaivaLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KaivaActivityAttributes.self) { context in
            KaivaLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region
                DynamicIslandExpandedRegion(.leading) {
                    AlbumArtView(urlString: context.state.albumArt)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.94, green: 0.62, blue: 0.15))
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(context.state.artist)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressBar(
                        elapsed: context.state.elapsedSeconds,
                        duration: context.state.durationSeconds
                    )
                    .frame(height: 3)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                }
            } compactLeading: {
                KaivaCompactLeadingView(state: context.state)
            } compactTrailing: {
                KaivaCompactTrailingView(state: context.state)
            } minimal: {
                KaivaMinimalView(state: context.state)
            }
            .keylineTint(Color(red: 0.94, green: 0.62, blue: 0.15))
            .contentMargins(.horizontal, 0, for: .expanded)
        }
    }
}
