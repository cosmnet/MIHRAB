import SwiftUI

// MARK: - Browse mode

enum QuranBrowseMode: String, CaseIterable, Identifiable {
    case suras, juz, hizb, bookmarks

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .suras: L10n.quranSuras
        case .juz: L10n.quranJuz
        case .hizb: L10n.quranHizb
        case .bookmarks: L10n.quranBookmarks
        }
    }
}

// MARK: - Library

/// The Qur'an's home: resume, hatim, and four ways into the text.
///
/// Nothing here is gated. This screen and everything it leads to is free, on
/// purpose — a reader is the floor of "one app for everything", not an upsell.
struct QuranLibraryView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var mode: QuranBrowseMode = .suras
    @State private var query = ""
    @State private var results: [QuranSearchResult] = []
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var bookmarks = QuranBookmarkStore.shared
    @State private var hatim = HatimStore.shared
    @State private var appeared = false

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            MihrabBackdrop(surface: .deen, ramadanMode: theme.isRamadanMode)

            ScrollView {
                LazyVStack(spacing: 20) {
                    if isSearching {
                        searchResults
                    } else {
                        resumeCard
                            .cardEntrance(index: 0, appeared: appeared, reduceMotion: reduceMotion)
                        hatimCard
                            .cardEntrance(index: 1, appeared: appeared, reduceMotion: reduceMotion)
                        modePicker
                        browseList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .mihrabTabSafeContent()
            }
            .mihrabTabScroll()
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationTitle(L10n.quranTitle)
        .searchable(text: $query, prompt: Text(L10n.quranSearchPrompt))
        .onChange(of: query) { _, new in scheduleSearch(new) }
        .onAppear {
            guard !appeared else { return }
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : MihrabMotion.standardAnimation) {
                appeared = true
            }
        }
        .task {
            // Warm the corpus while the list is being read, so the first tap
            // into a sura does not wait on a 1.3 MB decode.
            _ = try? await QuranTextStore.shared.load()
        }
    }

    // MARK: Resume

    @ViewBuilder
    private var resumeCard: some View {
        if let resume = bookmarks.resume, let sura = QuranCatalog.sura(resume.ref.sura) {
            NavigationLink {
                QuranReaderView(sura: sura, focus: resume.ref)
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.quranResumeTitle).ornamentalCaps()
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(sura.localizedName)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(MihrabColor.textPrimary)
                            Text(subtitle(for: resume.ref))
                                .font(.caption)
                                .foregroundStyle(MihrabColor.textSecondary)
                        }
                        Spacer()
                        Text(L10n.quranResumeAction)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MihrabColor.mint)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .mihrabShaderPanel(.kufic, cornerRadius: MihrabSpace.cardRadius, opacity: 0.4)
            }
            .buttonStyle(.plain)
            .pressable(reduceMotion)
        } else {
            NavigationLink {
                QuranReaderView(sura: QuranCatalog.suras[0])
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "book.pages")
                        .font(.title3)
                        .foregroundStyle(MihrabColor.brass)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.quranStartReading)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MihrabColor.textPrimary)
                        Text(L10n.quranSubtitle)
                            .font(.caption)
                            .foregroundStyle(MihrabColor.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: MihrabSpace.rowHeight)
                .mihrabSolidCard(cornerRadius: MihrabSpace.cardRadius)
            }
            .buttonStyle(.plain)
            .pressable(reduceMotion)
        }
    }

    private func subtitle(for ref: AyahRef) -> String {
        var parts = ["\(L10n.quranTitle) \(ref.citation)"]
        if let page = QuranCatalog.page(containing: ref) {
            parts.append(L10n.quranPageNumber(page))
        }
        if let juz = QuranCatalog.juzNumber(containing: ref) {
            parts.append(L10n.quranJuzNumber(juz))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: Hatim

    private var hatimCard: some View {
        NavigationLink { HatimView() } label: { HatimSummaryCard() }
            .buttonStyle(.plain)
            .pressable(reduceMotion)
    }

    // MARK: Browse

    private var modePicker: some View {
        Picker("", selection: $mode) {
            ForEach(QuranBrowseMode.allCases) { mode in
                Text(mode.localizedName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private var browseList: some View {
        switch mode {
        case .suras:
            ForEach(QuranCatalog.suras) { sura in
                NavigationLink { QuranReaderView(sura: sura) } label: { suraRow(sura) }
                    .buttonStyle(.plain)
            }
        case .juz:
            ForEach(QuranCatalog.juz) { division in
                divisionRow(division, title: L10n.quranJuzNumber(division.index))
            }
        case .hizb:
            ForEach(QuranCatalog.hizb) { division in
                divisionRow(division, title: L10n.quranHizbNumber(division.index))
            }
        case .bookmarks:
            bookmarkList
        }
    }

    private func suraRow(_ sura: SuraInfo) -> some View {
        HStack(spacing: 14) {
            Text("\(sura.number)")
                .font(.footnote.weight(.semibold).monospacedDigit())
                .foregroundStyle(MihrabColor.brass)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(sura.localizedName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(MihrabColor.textPrimary)
                Text("\(sura.revelation == .meccan ? L10n.quranMeccan : L10n.quranMedinan) · \(L10n.quranAyahCount(sura.ayahCount))")
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary)
            }

            Spacer(minLength: 8)

            Text(sura.arabicName)
                .font(MihrabFont.arabic(20))
                .foregroundStyle(MihrabColor.mint)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: MihrabSpace.rowHeight)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func divisionRow(_ division: QuranDivision, title: String) -> some View {
        if let sura = QuranCatalog.sura(division.start.sura) {
            NavigationLink {
                QuranReaderView(sura: sura, focus: division.start)
            } label: {
                HStack(spacing: 14) {
                    Text("\(division.index)")
                        .font(.footnote.weight(.semibold).monospacedDigit())
                        .foregroundStyle(MihrabColor.brass)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(MihrabColor.textPrimary)
                        Text("\(sura.localizedName) \(division.start.citation)")
                            .font(.caption2)
                            .foregroundStyle(MihrabColor.textSecondary)
                    }
                    Spacer()
                    if let page = QuranCatalog.page(containing: division.start) {
                        Text(L10n.quranPageNumber(page))
                            .font(.caption2)
                            .foregroundStyle(MihrabColor.textTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: MihrabSpace.rowHeight)
                .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var bookmarkList: some View {
        if bookmarks.bookmarks.isEmpty {
            MihrabEmptyState(
                symbol: "bookmark",
                title: L10n.quranBookmarksEmptyTitle,
                message: L10n.quranBookmarksEmptyBody,
                retry: nil
            )
        } else {
            ForEach(bookmarks.bookmarks) { bookmark in
                if let sura = QuranCatalog.sura(bookmark.ref.sura) {
                    NavigationLink {
                        QuranReaderView(sura: sura, focus: bookmark.ref)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bookmark.fill")
                                .font(.footnote)
                                .foregroundStyle(MihrabColor.brass)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(sura.localizedName) \(bookmark.ref.citation)")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(MihrabColor.textPrimary)
                                if let note = bookmark.note {
                                    Text(note)
                                        .font(.caption2)
                                        .foregroundStyle(MihrabColor.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: MihrabSpace.rowHeight)
                        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    // A LazyVStack row, not a List row, so removal lives in a
                    // context menu rather than a swipe that would never fire.
                    .contextMenu {
                        Button(role: .destructive) {
                            HapticsEngine.shared.warning()
                            bookmarks.removeBookmark(bookmark.ref)
                        } label: {
                            Label(L10n.quranRemoveBookmark, systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: Search

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            searching = false
            return
        }
        searching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            let found = await QuranSearchEngine.shared.search(
                trimmed,
                translationPackID: QuranReadingPreferences.shared.activeTranslationPack?.id
            )
            guard !Task.isCancelled else { return }
            results = found
            searching = false
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if let ref = QuranSearchEngine.citation(in: query), let sura = QuranCatalog.sura(ref.sura) {
            NavigationLink {
                QuranReaderView(sura: sura, focus: ref)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(MihrabColor.emerald)
                    Text("\(L10n.quranJumpToReference) \(sura.localizedName) \(ref.citation)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MihrabColor.textPrimary)
                    Spacer()
                }
                .padding(16)
                .frame(minHeight: MihrabSpace.hit)
                .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }

        if searching {
            HStack(spacing: 10) {
                ProgressView()
                Text(L10n.quranSearchPrompt)
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
        } else if results.isEmpty {
            MihrabEmptyState(
                symbol: "magnifyingglass",
                title: L10n.quranSearchEmptyTitle,
                message: L10n.quranSearchEmptyBody,
                retry: nil
            )
        } else {
            Text(L10n.quranSearchResults(results.count))
                .ornamentalCaps()
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(results) { result in
                if let sura = QuranCatalog.sura(result.ref.sura) {
                    NavigationLink {
                        QuranReaderView(sura: sura, focus: result.ref)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(sura.localizedName) \(result.ref.citation)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(MihrabColor.brass)
                                Spacer()
                                if result.matchedTranslation {
                                    Text(L10n.quranSearchMatchedTranslation)
                                        .font(.caption2)
                                        .foregroundStyle(MihrabColor.textTertiary)
                                }
                            }
                            Text(result.arabic)
                                .font(MihrabFont.arabic(21))
                                .foregroundStyle(MihrabColor.textPrimary)
                                .lineLimit(3)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .environment(\.layoutDirection, .rightToLeft)
                            if let line = result.translation {
                                Text(line)
                                    .font(.footnote)
                                    .foregroundStyle(MihrabColor.textSecondary)
                                    .lineLimit(3)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Standalone entry

/// Wrapped in its own `NavigationStack` so it can be presented as a sheet from
/// anywhere (Settings, Today, Deen) without inheriting someone else's stack.
struct QuranView: View {
    var body: some View {
        NavigationStack {
            QuranLibraryView()
        }
    }
}
