import SwiftUI

/// Launch curtain: the mihrab niche draws itself, the lamp inside it settles,
/// then the wordmark is written letter by letter. ~1.2 s, then it
/// cross-fades into the app. Reduce Motion gets the finished frame instantly.
struct SplashOverlay: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var archProgress: CGFloat = 0
    @State private var lampIn = false
    @State private var lettersRevealed = 0
    @State private var taglineIn = false
    @State private var haloOpacity: Double = 0

    private let wordmark = Array("Mihrab")

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 26) {
                mark
                wordmarkView
                Text(L10n.obSplashSubtitle)
                    .font(MihrabFont.quoteItalic(17))
                    .foregroundStyle(MihrabColor.textSecondary)
                    .opacity(taglineIn ? 1 : 0)
                    .blur(radius: taglineIn ? 0 : 4)
            }
            .padding(32)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mihrab")
        .task { await run() }
    }

    // MARK: - Pieces

    private var backdrop: some View {
        ZStack {
            MihrabColor.abyss
            RadialGradient(
                colors: [MihrabColor.forest.opacity(0.9), MihrabColor.abyss],
                center: .center,
                startRadius: 20,
                endRadius: 520
            )
            RadialGradient(
                colors: [MihrabColor.brass.opacity(0.22), .clear],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 4,
                endRadius: 260
            )
            .opacity(haloOpacity)
        }
        .ignoresSafeArea()
    }

    /// The brand mark draws itself: the niche outline strokes on, then the
    /// lamp inside it settles. `MihrabMark` authors its arch as one
    /// continuous path precisely so `drawProgress` reads as a single line.
    private var mark: some View {
        MihrabMark(
            height: 172,
            drawProgress: archProgress,
            detailOpacity: lampIn ? 1 : 0
        )
        .scaleEffect(lampIn ? 1 : 0.985)
        .frame(width: 176, height: 196)
        .accessibilityHidden(true)
    }

    private var wordmarkView: some View {
        HStack(spacing: 1) {
            ForEach(Array(wordmark.enumerated()), id: \.offset) { index, character in
                let shown = index < lettersRevealed
                Text(String(character))
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .opacity(shown ? 1 : 0)
                    .blur(radius: shown ? 0 : 6)
                    .offset(y: shown ? 0 : 10)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Timeline

    @MainActor
    private func run() async {
        guard !reduceMotion else {
            archProgress = 1
            lampIn = true
            lettersRevealed = wordmark.count
            taglineIn = true
            haloOpacity = 1
            try? await Task.sleep(for: .milliseconds(260))
            onFinish()
            return
        }

        withAnimation(.easeInOut(duration: 0.7)) { archProgress = 1 }
        withAnimation(.easeInOut(duration: 1.0)) { haloOpacity = 1 }

        try? await Task.sleep(for: .milliseconds(260))
        withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) { lampIn = true }

        try? await Task.sleep(for: .milliseconds(200))
        for step in 1...wordmark.count {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { lettersRevealed = step }
            try? await Task.sleep(for: .milliseconds(52))
        }

        withAnimation(.easeOut(duration: 0.45)) { taglineIn = true }

        try? await Task.sleep(for: .milliseconds(420))
        onFinish()
    }
}
