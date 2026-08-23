import SwiftUI
import UIKit

// MARK: - Numerals

enum ArabicNumerals {
    private static let digits: [Character] = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]

    /// Eastern Arabic-Indic digits, used inside the ayah medallion regardless of
    /// UI language — the medallion is part of the mushaf, not the interface.
    static func string(_ value: Int) -> String {
        String(String(value).map { char in
            char.wholeNumberValue.map { digits[$0] } ?? char
        })
    }

    /// `۝` end-of-ayah sign with the number inside, for continuous flow.
    static func endOfAyah(_ value: Int) -> String {
        "\u{06DD}" + string(value)
    }
}

// MARK: - Reader

/// The reading screen.
///
/// Loads one sura at a time. Even the longest — al-Baqara, 286 ayahs — is a
/// single `LazyVStack` whose rows are plain `Text`, so scrolling stays on the
/// fast path and the 6,236-ayah corpus is never realised as views.
struct QuranReaderView: View {
    let sura: SuraInfo
    /// Ayah to scroll to on open. `nil` starts at the top.
    var focus: AyahRef?

    @State private var ayahs: [Ayah] = []
    @State private var translationLines: [String]?
    @State private var basmala: String = ""
    @State private var loadFailed = false
    @State private var isLoading = true

    @State private var prefs = QuranReadingPreferences.shared
    @State private var bookmarks = QuranBookmarkStore.shared
    @State private var hatim = HatimStore.shared

    @State private var showDisplaySettings = false
    @State private var showLicence = false
    @State private var shareTarget: Ayah?

    /// Ayahs that scrolled past this session, counted once each.
    @State private var seen: Set<AyahRef> = []
    @State private var furthest: AyahRef?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .footnote) private var medallion: CGFloat = 30

    private var mode: QuranReadingMode { prefs.mode }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    header
                    if isLoading {
                        loadingRow
                    } else if loadFailed {
                        failure
                    } else {
                        content
                        footer
                    }
                }
                .padding(.horizontal, prefs.theme.horizontalPadding)
                .mihrabTabSafeContent()
            }
            .onAppear {
                guard let focus else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                        proxy.scrollTo(focus.id, anchor: .center)
                    }
                }
            }
        }
        .background(mode.background.ignoresSafeArea())
        .preferredColorScheme(mode.preferredColorScheme)
        .navigationTitle(sura.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .task { await load() }
        .onDisappear { endSession() }
        .onChange(of: prefs.keepAwake) { _, on in
            UIApplication.shared.isIdleTimerDisabled = on
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = prefs.keepAwake }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .sheet(isPresented: $showDisplaySettings) {
            QuranDisplaySettingsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLicence) { QuranLicenceView() }
        .sheet(item: $shareTarget) { ayah in
            QuranVerseShareSheet(ayah: ayah, sura: sura,
                                 translation: translation(for: ayah.ref))
        }
    }

    // MARK: Loading

    private func load() async {
        isLoading = true
        do {
            async let text = QuranTextStore.shared.ayahs(sura: sura.number)
            async let bism = QuranTextStore.shared.basmala()
            ayahs = try await text
            basmala = try await bism
            if let packID = prefs.activeTranslationPack?.id {
                translationLines = await TranslationStore.shared.lines(packID: packID, sura: sura.number)
            }
            loadFailed = false
        } catch {
            loadFailed = true
        }
        isLoading = false
    }

    private func translation(for ref: AyahRef) -> String? {
        guard let lines = translationLines, ref.ayah <= lines.count else { return nil }
        let line = lines[ref.ayah - 1]
        return line.isEmpty ? nil : line
    }

    // MARK: Session accounting

    private func note(_ ref: AyahRef) {
        guard seen.insert(ref).inserted else { return }
        if (furthest.map { ref > $0 } ?? true) { furthest = ref }
    }

    /// One write at the end of the session rather than one per ayah — the
    /// reader must not touch `UserDefaults` on every scroll tick.
    private func endSession() {
        guard !seen.isEmpty else { return }
        if let furthest {
            bookmarks.noteReading(furthest)
            hatim.recordReading(ayahs: [furthest])
        }
        bookmarks.logAyahsRead(seen.count)
        seen.removeAll()
    }

    // MARK: Chrome

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticsEngine.shared.light()
                showDisplaySettings = true
            } label: {
                Image(systemName: "textformat.size")
            }
            .accessibilityLabel(Text(L10n.quranDisplay))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker(L10n.quranReadingMode, selection: $prefs.mode) {
                    ForEach(QuranReadingMode.allCases) { mode in
                        Label(mode.localizedName, systemImage: mode.symbolName).tag(mode)
                    }
                }
                Toggle(L10n.quranKeepAwake, isOn: $prefs.keepAwake)
                Divider()
                Button {
                    showLicence = true
                } label: {
                    Label(L10n.quranTextSource, systemImage: "info.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text(sura.arabicName)
                .font(MihrabFont.arabic(min(prefs.arabicSize * 1.1, 40)))
                .foregroundStyle(mode.ink)

            Text([
                sura.revelation == .meccan ? L10n.quranMeccan : L10n.quranMedinan,
                L10n.quranAyahCount(sura.ayahCount)
            ].joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(mode.secondaryInk)

            if sura.hasSeparateBasmala && !basmala.isEmpty {
                Text(basmala)
                    .font(MihrabFont.arabic(prefs.arabicSize * 0.92))
                    .foregroundStyle(mode.ornament)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .accessibilityLabel(Text(basmala))
            }

            Rectangle()
                .fill(mode.ornament.opacity(0.35))
                .frame(width: 56, height: 1)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(L10n.quranLoading)
                .font(.footnote)
                .foregroundStyle(mode.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var failure: some View {
        MihrabEmptyState(
            symbol: "book.closed",
            title: L10n.quranLoadFailedTitle,
            message: L10n.quranLoadFailedBody,
            retryTitle: L10n.tryAgain,
            retry: { Task { await load() } }
        )
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private var content: some View {
        switch prefs.flow {
        case .verse:
            ForEach(ayahs) { ayah in
                verseRow(ayah)
                    .id(ayah.ref.id)
                    .onAppear { note(ayah.ref) }
            }
        case .flowing:
            // Chunked so the lazy stack still has something to be lazy about,
            // and so no single `Text` has to lay out 286 ayahs at once.
            ForEach(Array(chunks.enumerated()), id: \.offset) { index, chunk in
                flowingBlock(chunk)
                    .id(chunk.first?.ref.id ?? "chunk-\(index)")
                    .onAppear { chunk.forEach { note($0.ref) } }
            }
        }
    }

    private var chunks: [[Ayah]] {
        stride(from: 0, to: ayahs.count, by: 10).map {
            Array(ayahs[$0..<min($0 + 10, ayahs.count)])
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Rectangle()
                .fill(mode.ornament.opacity(0.3))
                .frame(width: 90, height: 1)

            HStack(spacing: 20) {
                if sura.number > 1, let previous = QuranCatalog.sura(sura.number - 1) {
                    NavigationLink {
                        QuranReaderView(sura: previous)
                    } label: {
                        Label(previous.localizedName, systemImage: "chevron.left")
                            .font(.footnote.weight(.medium))
                    }
                }
                Spacer(minLength: 0)
                if sura.number < 114, let next = QuranCatalog.sura(sura.number + 1) {
                    NavigationLink {
                        QuranReaderView(sura: next)
                    } label: {
                        Label(next.localizedName, systemImage: "chevron.right")
                            .labelStyle(.titleAndIcon)
                            .font(.footnote.weight(.medium))
                    }
                }
            }
            .tint(mode.ornament)
            .frame(minHeight: MihrabSpace.hit)
        }
        .padding(.top, 26)
    }

    // MARK: Rows

    private func verseRow(_ ayah: Ayah) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                numberMedallion(ayah.ref.ayah)
                Text(ayah.text)
                    .font(prefs.arabicFont)
                    .lineSpacing(prefs.effectiveLineSpacing)
                    .foregroundStyle(mode.ink)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                    .textSelection(.enabled)
            }

            if let sajda = ayah.sajda {
                sajdaMark(sajda)
            }

            if let line = translation(for: ayah.ref) {
                Text(line)
                    .font(.callout)
                    .lineSpacing(3)
                    .foregroundStyle(mode.secondaryInk)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if bookmarks.isBookmarked(ayah.ref) {
                Label(L10n.quranBookmarks, systemImage: "bookmark.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(mode.ornament)
            }
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(mode.secondaryInk.opacity(0.12))
                .frame(height: 1)
        }
        .contentShape(Rectangle())
        .contextMenu { ayahMenu(ayah) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(sura.localizedName) \(ayah.ref.citation)"))
    }

    private func flowingBlock(_ chunk: [Ayah]) -> some View {
        let joined = chunk
            .map { "\($0.text) \(ArabicNumerals.endOfAyah($0.ref.ayah))" }
            .joined(separator: " ")

        return Text(joined)
            .font(prefs.arabicFont)
            .lineSpacing(prefs.effectiveLineSpacing)
            .foregroundStyle(mode.ink)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .rightToLeft)
            .textSelection(.enabled)
            .padding(.vertical, 8)
            .accessibilityLabel(
                Text("\(sura.localizedName) \(chunk.first?.ref.ayah ?? 0)–\(chunk.last?.ref.ayah ?? 0)")
            )
    }

    private func numberMedallion(_ number: Int) -> some View {
        Text(ArabicNumerals.string(number))
            .font(.footnote.weight(.medium))
            .foregroundStyle(mode.ornament)
            .frame(width: medallion, height: medallion)
            .background {
                ZStack {
                    Circle().strokeBorder(mode.ornament.opacity(0.55), lineWidth: 1)
                    // Eight-point rosette, the mushaf's ayah mark.
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .strokeBorder(mode.ornament.opacity(0.18), lineWidth: 1)
                            .frame(width: medallion * 0.86, height: medallion * 0.86)
                            .rotationEffect(.degrees(Double(index) * 45))
                            .scaleEffect(x: 1, y: 0.62)
                    }
                }
            }
            .accessibilityHidden(true)
    }

    private func sajdaMark(_ sajda: SajdaMark) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.mind.and.body")
                .font(.caption2)
            Text(sajda.isObligatory ? L10n.quranSajdaObligatory : L10n.quranSajdaRecommended)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(mode.ornament)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(mode.ornament.opacity(0.12)))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(Text(L10n.quranSajdaMark))
        .accessibilityHint(Text(L10n.quranSajdaSchoolsNote))
    }

    @ViewBuilder
    private func ayahMenu(_ ayah: Ayah) -> some View {
        Button {
            HapticsEngine.shared.light()
            _ = bookmarks.toggleBookmark(ayah.ref)
        } label: {
            Label(
                bookmarks.isBookmarked(ayah.ref) ? L10n.quranRemoveBookmark : L10n.quranAddBookmark,
                systemImage: bookmarks.isBookmarked(ayah.ref) ? "bookmark.slash" : "bookmark"
            )
        }
        Button {
            HapticsEngine.shared.light()
            bookmarks.noteReading(ayah.ref)
        } label: {
            Label(L10n.quranSetResume, systemImage: "arrow.turn.down.right")
        }
        Button {
            UIPasteboard.general.string = shareableText(ayah)
            HapticsEngine.shared.success()
        } label: {
            Label(L10n.quranCopy, systemImage: "doc.on.doc")
        }
        Button {
            shareTarget = ayah
        } label: {
            Label(L10n.quranShareVerse, systemImage: "square.and.arrow.up")
        }
    }

    private func shareableText(_ ayah: Ayah) -> String {
        var parts = [ayah.text]
        if let line = translation(for: ayah.ref) { parts.append(line) }
        parts.append("— \(sura.localizedName) \(ayah.ref.citation)")
        return parts.joined(separator: "\n\n")
    }
}
