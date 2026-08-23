import SwiftUI

/// Launch curtain: the mihrab arch draws itself, a brass crescent settles into
/// the niche, then the wordmark is written letter by letter. ~1.2 s, then it
/// cross-fades into the app. Reduce Motion gets the finished frame instantly.
struct SplashOverlay: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var archProgress: CGFloat = 0
    @State private var crescentIn = false
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

    private var mark: some View {
        ZStack {
            SplashArchShape()
                .trim(from: 0, to: archProgress)
                .stroke(
                    LinearGradient(
                        colors: [MihrabColor.brass, MihrabColor.brass.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 132, height: 172)

            BrassCrescent(diameter: 46, opacity: 0.9)
                .offset(y: -14)
                .scaleEffect(crescentIn ? 1 : 0.55)
                .opacity(crescentIn ? 1 : 0)
        }
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
            crescentIn = true
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
        withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) { crescentIn = true }

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

/// Splash-only arch: drawn from the floor up one side, over the crown and down
/// the other, so `.trim` reads as a single continuous stroke.
private struct SplashArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.08
        let shoulder = rect.midY + 10
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: shoulder))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - inset, y: shoulder),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        return path
    }
}
