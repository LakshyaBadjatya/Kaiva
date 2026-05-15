import ActivityKit
import SwiftUI
import WidgetKit
import AppIntents

// ── Kaiva palette (mirrors Stitch tailwind config) ──────────────────────────

private enum KaivaPalette {
    static let background   = Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0A/255) // #0A0A0A true black
    static let card         = Color(red: 0x13/255, green: 0x13/255, blue: 0x13/255) // #131313 surface
    static let primary      = Color(red: 0xFF/255, green: 0xBF/255, blue: 0x6F/255) // #FFBF6F sand
    static let primaryDeep  = Color(red: 0xEF/255, green: 0x9F/255, blue: 0x27/255) // #EF9F27 amber
    static let onAccent     = Color(red: 0x46/255, green: 0x2A/255, blue: 0x00/255) // #462A00 dark-on-sand
    static let onSurfaceVar = Color(red: 0xD7/255, green: 0xC3/255, blue: 0xAE/255) // #D7C3AE muted
    static let surfaceHigh  = Color(red: 0x2A/255, green: 0x2A/255, blue: 0x2A/255) // #2A2A2A
    static let border       = Color.white.opacity(0.08)
}

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
                    KaivaPalette.surfaceHigh
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(KaivaPalette.primary)
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

// ── Animated equalizer (Compact trailing — matches Stitch 4-bar amber) ──────

struct EqualizerBars: View {
    let isPlaying: Bool
    let barCount: Int
    let maxHeight: CGFloat

    @State private var phase: Double = 0

    init(isPlaying: Bool, barCount: Int = 4, maxHeight: CGFloat = 12) {
        self.isPlaying = isPlaying
        self.barCount = barCount
        self.maxHeight = maxHeight
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(KaivaPalette.primary)
                    .frame(width: 3, height: barHeight(for: i))
                    .opacity(opacity(for: i))
            }
        }
        .frame(height: maxHeight)
        .animation(
            isPlaying
                ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
                : .default,
            value: phase
        )
        .onAppear {
            if isPlaying { phase = 1 }
        }
        .onChange(of: isPlaying) { newValue in
            phase = newValue ? 1 : 0
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        // Static heights mirroring the mockup (h-2, h-3, h-1.5, h-2.5)
        let baseRatios: [CGFloat] = [0.55, 1.0, 0.40, 0.75]
        let base = baseRatios[index % baseRatios.count] * maxHeight
        if !isPlaying { return base * 0.5 }
        // Phase shift gives each bar a different animated height
        let pulse = sin(phase * .pi + Double(index)) * 0.35
        return max(3, base + CGFloat(pulse) * maxHeight)
    }

    private func opacity(for index: Int) -> Double {
        let ops: [Double] = [0.8, 1.0, 0.9, 0.7]
        return isPlaying ? ops[index % ops.count] : 0.5
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
                    .fill(Color.white.opacity(0.14))
                    .frame(height: 3)
                Capsule()
                    .fill(KaivaPalette.primary)
                    .frame(width: max(3, geo.size.width * progress), height: 3)
            }
        }
        .frame(height: 3)
    }
}

// ── Time formatting ─────────────────────────────────────────────────────────

private func formatTime(_ seconds: Double) -> String {
    let s = max(0, Int(seconds))
    return String(format: "%d:%02d", s / 60, s % 60)
}

private func formatRemaining(_ elapsed: Double, _ duration: Double) -> String {
    let remaining = max(0, duration - elapsed)
    let s = Int(remaining)
    return String(format: "-%d:%02d", s / 60, s % 60)
}

// ── Lock Screen / Notification Banner ───────────────────────────────────────
// Mirrors the Expanded mockup but slightly compressed for banner constraints.

@available(iOS 16.2, *)
struct KaivaLockScreenView: View {
    let state: KaivaActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                AlbumArtView(urlString: state.albumArt)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(KaivaPalette.border, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(state.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(KaivaPalette.primary)
                        .lineLimit(1)
                    Text(state.artist)
                        .font(.system(size: 13))
                        .foregroundColor(KaivaPalette.onSurfaceVar.opacity(0.75))
                        .lineLimit(1)
                }
                Spacer(minLength: 8)

                // Controls — prev / amber play-pause / next
                HStack(spacing: 18) {
                    if #available(iOS 17.0, *) {
                        sideControl(
                            systemName: "backward.fill",
                            intentBuilder: { KaivaPreviousIntent() }
                        )
                        playPauseButton(
                            isPlaying: state.isPlaying,
                            intentBuilder: { KaivaPlayPauseIntent() }
                        )
                        sideControl(
                            systemName: "forward.fill",
                            intentBuilder: { KaivaNextIntent() }
                        )
                    } else {
                        staticSide(systemName: "backward.fill")
                        staticPlayPause(isPlaying: state.isPlaying)
                        staticSide(systemName: "forward.fill")
                    }
                }
            }

            // Progress bar with timestamps
            HStack(spacing: 10) {
                Text(formatTime(state.elapsedSeconds))
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundColor(KaivaPalette.onSurfaceVar.opacity(0.5))
                    .frame(width: 30, alignment: .trailing)
                ProgressBar(elapsed: state.elapsedSeconds, duration: state.durationSeconds)
                Text(formatTime(state.durationSeconds))
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundColor(KaivaPalette.onSurfaceVar.opacity(0.5))
                    .frame(width: 30, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(KaivaPalette.background)
    }

    // Amber filled circular play/pause with dark icon (the Stitch hero control)
    @available(iOS 17.0, *)
    @ViewBuilder
    private func playPauseButton<I: AppIntent>(
        isPlaying: Bool,
        intentBuilder: @escaping () -> I
    ) -> some View {
        Button(intent: intentBuilder()) {
            ZStack {
                Circle().fill(KaivaPalette.primary).frame(width: 44, height: 44)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(KaivaPalette.onAccent)
            }
        }
        .buttonStyle(.plain)
    }

    @available(iOS 17.0, *)
    @ViewBuilder
    private func sideControl<I: AppIntent>(
        systemName: String,
        intentBuilder: @escaping () -> I
    ) -> some View {
        Button(intent: intentBuilder()) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func staticPlayPause(isPlaying: Bool) -> some View {
        ZStack {
            Circle().fill(KaivaPalette.primary).frame(width: 44, height: 44)
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(KaivaPalette.onAccent)
        }
    }

    @ViewBuilder
    private func staticSide(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white.opacity(0.85))
            .frame(width: 30, height: 30)
    }
}

// ── Dynamic Island — Compact leading (album art) ────────────────────────────

@available(iOS 16.2, *)
struct KaivaCompactLeadingView: View {
    let state: KaivaActivityAttributes.ContentState

    var body: some View {
        AlbumArtView(urlString: state.albumArt)
            .frame(width: 24, height: 24)
            .clipShape(Circle())
    }
}

// ── Dynamic Island — Compact trailing (equalizer bars) ──────────────────────

@available(iOS 16.2, *)
struct KaivaCompactTrailingView: View {
    let state: KaivaActivityAttributes.ContentState

    var body: some View {
        EqualizerBars(isPlaying: state.isPlaying, barCount: 4, maxHeight: 12)
            .padding(.trailing, 4)
    }
}

// ── Dynamic Island — Minimal ────────────────────────────────────────────────

@available(iOS 16.2, *)
struct KaivaMinimalView: View {
    let state: KaivaActivityAttributes.ContentState

    var body: some View {
        AlbumArtView(urlString: state.albumArt)
            .frame(width: 20, height: 20)
            .clipShape(Circle())
    }
}

// ── Widget configuration ────────────────────────────────────────────────────

@available(iOS 16.2, *)
struct KaivaLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KaivaActivityAttributes.self) { context in
            KaivaLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // Top region: art + title/artist + equalizer
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 12) {
                        AlbumArtView(urlString: context.state.albumArt)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(KaivaPalette.primary)
                                .lineLimit(1)
                            Text(context.state.artist)
                                .font(.system(size: 12))
                                .foregroundColor(KaivaPalette.onSurfaceVar.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EqualizerBars(
                        isPlaying: context.state.isPlaying,
                        barCount: 5,
                        maxHeight: 22
                    )
                    .padding(.trailing, 6)
                }
                // Center region: progress bar with timestamps
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 10) {
                        Text(formatTime(context.state.elapsedSeconds))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 28, alignment: .trailing)
                        ProgressBar(
                            elapsed: context.state.elapsedSeconds,
                            duration: context.state.durationSeconds
                        )
                        Text(formatRemaining(
                            context.state.elapsedSeconds,
                            context.state.durationSeconds
                        ))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 32, alignment: .leading)
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 4)
                }
                // Bottom region: prev / play-pause / next
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 36) {
                        if #available(iOS 17.0, *) {
                            expandedControl(
                                systemName: "backward.fill",
                                size: 24,
                                intentBuilder: { KaivaPreviousIntent() }
                            )
                            expandedPlayPause(
                                isPlaying: context.state.isPlaying,
                                intentBuilder: { KaivaPlayPauseIntent() }
                            )
                            expandedControl(
                                systemName: "forward.fill",
                                size: 24,
                                intentBuilder: { KaivaNextIntent() }
                            )
                        } else {
                            staticControl(systemName: "backward.fill", size: 24)
                            staticExpandedPlayPause(isPlaying: context.state.isPlaying)
                            staticControl(systemName: "forward.fill", size: 24)
                        }
                    }
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                KaivaCompactLeadingView(state: context.state)
            } compactTrailing: {
                KaivaCompactTrailingView(state: context.state)
            } minimal: {
                KaivaMinimalView(state: context.state)
            }
            .keylineTint(KaivaPalette.primary)
        }
    }

    @available(iOS 17.0, *)
    @ViewBuilder
    private func expandedControl<I: AppIntent>(
        systemName: String,
        size: CGFloat,
        intentBuilder: @escaping () -> I
    ) -> some View {
        Button(intent: intentBuilder()) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }

    @available(iOS 17.0, *)
    @ViewBuilder
    private func expandedPlayPause<I: AppIntent>(
        isPlaying: Bool,
        intentBuilder: @escaping () -> I
    ) -> some View {
        Button(intent: intentBuilder()) {
            ZStack {
                Circle().fill(KaivaPalette.primary).frame(width: 48, height: 48)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(KaivaPalette.onAccent)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func staticControl(systemName: String, size: CGFloat) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(.white.opacity(0.85))
    }

    @ViewBuilder
    private func staticExpandedPlayPause(isPlaying: Bool) -> some View {
        ZStack {
            Circle().fill(KaivaPalette.primary).frame(width: 48, height: 48)
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(KaivaPalette.onAccent)
        }
    }
}
