import SwiftUI
import UniformTypeIdentifiers

/// Drop-in `Section`s for the Settings `Form`: which sound announces each
/// prayer, preview volume, and importing your own licensed recording.
///
/// Embed with `AdhanSettingsSection()` — it returns a `Group` of `Section`s,
/// exactly like `AppearanceSettingsSection`.
struct AdhanSettingsSection: View {
    @State private var library = AdhanLibrary.shared
    @State private var preferences = ReminderPreferences.shared
    @State private var picking: PickTarget?
    @State private var showImporter = false
    @State private var showPaywall = false
    @State private var importAlert: String?

    init() {}

    private let rowBackground = MihrabColor.moss.opacity(0.72)

    private var isPremium: Bool {
        SubscriptionManager.shared.hasAccess(to: .customAdhan)
    }

    var body: some View {
        Group {
            defaultSoundSection
            perPrayerSection
            librarySection
        }
        .sheet(item: $picking) { target in
            AdhanSoundPickerSheet(target: target)
        }
        .sheet(isPresented: $showPaywall) { PaywallView(source: .feature) }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.audio, .mp3, .wav, .aiff, .mpeg4Audio],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert(
            L10n.adhSectionLibrary,
            isPresented: Binding(
                get: { importAlert != nil },
                set: { if !$0 { importAlert = nil } }
            )
        ) {
            Button("OK", role: .cancel) { importAlert = nil }
        } message: {
            Text(importAlert ?? "")
        }
        .task { library.prepare() }
        .onDisappear { library.stopPreview() }
    }

    // MARK: - Default sound

    private var defaultSoundSection: some View {
        Section {
            Button {
                picking = .all
            } label: {
                HStack {
                    Text(L10n.adhSameForAll)
                        .foregroundStyle(MihrabColor.textPrimary)
                    Spacer()
                    Text(library.defaultSound.localizedName)
                        .foregroundStyle(MihrabColor.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textTertiary)
                }
            }
            .frame(minHeight: 44)
            .accessibilityLabel(L10n.adhSameForAll)
            .accessibilityValue(library.defaultSound.localizedName)

            volumeRow
        } header: {
            Text(L10n.adhSectionSound)
        } footer: {
            Text(L10n.adhVolumeFooter)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .listRowBackground(rowBackground)
    }

    private var volumeRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.adhVolume)
                .font(.subheadline)
            Slider(
                value: Binding(
                    get: { preferences.previewVolume },
                    set: { preferences.previewVolume = $0 }
                ),
                in: 0...1
            ) {
                Text(L10n.adhVolume)
            } minimumValueLabel: {
                Image(systemName: "speaker.fill").font(.caption2)
            } maximumValueLabel: {
                Image(systemName: "speaker.wave.3.fill").font(.caption2)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Per prayer

    private var perPrayerSection: some View {
        Section {
            ForEach(Prayer.allCases.filter(\.isNotifiable)) { prayer in
                Button {
                    if isPremium {
                        picking = .prayer(prayer)
                    } else {
                        showPaywall = true
                    }
                } label: {
                    HStack {
                        Image(systemName: prayer.symbolName)
                            .font(.caption)
                            .foregroundStyle(MihrabColor.textSecondary)
                            .frame(width: 22)
                        Text(prayer.localizedName)
                            .foregroundStyle(MihrabColor.textPrimary)
                        Spacer()
                        if !isPremium {
                            PremiumLockBadge(compact: true)
                        } else {
                            Text(library.sound(for: prayer).localizedName)
                                .font(.subheadline)
                                .foregroundStyle(
                                    library.hasOverride(for: prayer)
                                        ? MihrabColor.mint
                                        : MihrabColor.textTertiary
                                )
                                .lineLimit(1)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(MihrabColor.textTertiary)
                    }
                }
                .frame(minHeight: 44)
                .accessibilityLabel(prayer.localizedName)
                .accessibilityValue(library.sound(for: prayer).localizedName)
            }
        } header: {
            Text(L10n.adhSectionPerPrayer)
        } footer: {
            Text(L10n.adhFajrHint)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - Library

    private var librarySection: some View {
        Section {
            Button {
                if isPremium { showImporter = true } else { showPaywall = true }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(MihrabColor.mint)
                    Text(L10n.adhImport)
                        .foregroundStyle(MihrabColor.textPrimary)
                    Spacer()
                    if !isPremium { PremiumLockBadge(compact: true) }
                }
            }
            .frame(minHeight: 44)

            ForEach(library.available.filter(\.isRemovable)) { sound in
                HStack {
                    Text(sound.localizedName)
                    Spacer()
                    Button(role: .destructive) {
                        library.remove(sound)
                        HapticsEngine.shared.warning()
                        Task { await NotificationEngine.shared.rescheduleAll() }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("\(L10n.adhDelete) \(sound.localizedName)")
                }
                .frame(minHeight: 44)
            }
        } header: {
            Text(L10n.adhSectionLibrary)
        } footer: {
            Text(L10n.adhImportFooter + "\n\n" + L10n.adhBundledEmptyNote)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - Import

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                _ = try library.importSound(from: url)
                HapticsEngine.shared.success()
                importAlert = library.lastImportMessage
                library.lastImportMessage = nil
                Task { await NotificationEngine.shared.rescheduleAll() }
            } catch {
                HapticsEngine.shared.warning()
                importAlert = (error as? AdhanImportError)?.errorDescription
                    ?? L10n.adhImportFailedCopy
            }
        case .failure:
            importAlert = L10n.adhImportFailedCopy
        }
    }

    enum PickTarget: Identifiable, Hashable {
        case all
        case prayer(Prayer)

        var id: String {
            switch self {
            case .all: "all"
            case .prayer(let prayer): prayer.rawValue
            }
        }
    }
}

// MARK: - Picker sheet

/// The sound list, with a real preview button on every row — choosing an adhan
/// by name alone is guesswork.
struct AdhanSoundPickerSheet: View {
    let target: AdhanSettingsSection.PickTarget

    @Environment(\.dismiss) private var dismiss
    @State private var library = AdhanLibrary.shared

    private var selectedID: String {
        switch target {
        case .all: library.defaultSound.id
        case .prayer(let prayer): library.sound(for: prayer).id
        }
    }

    private var title: String {
        switch target {
        case .all: L10n.adhSectionSound
        case .prayer(let prayer): prayer.localizedName
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(library.available) { sound in
                        row(for: sound)
                    }
                } footer: {
                    Text(L10n.adhImportFooter)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                .listRowBackground(MihrabColor.moss.opacity(0.72))

                if case .prayer(let prayer) = target, library.hasOverride(for: prayer) {
                    Section {
                        Button(L10n.adhSameForAll) {
                            library.clearOverride(for: prayer)
                            Task { await NotificationEngine.shared.rescheduleAll() }
                            dismiss()
                        }
                        .frame(minHeight: 44)
                    }
                    .listRowBackground(MihrabColor.moss.opacity(0.72))
                }
            }
            .scrollContentBackground(.hidden)
            .background(MihrabBackdrop(ramadanMode: false).ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
        .onDisappear { library.stopPreview() }
    }

    private func row(for sound: AdhanSound) -> some View {
        HStack(spacing: 12) {
            Button {
                select(sound)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: sound.id == selectedID ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(
                            sound.id == selectedID ? MihrabColor.mint : MihrabColor.textTertiary
                        )
                    Text(sound.localizedName)
                        .foregroundStyle(MihrabColor.textPrimary)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if sound.fileName != nil {
                Button {
                    if library.previewingSoundID == sound.id {
                        library.stopPreview()
                    } else {
                        library.preview(sound)
                    }
                } label: {
                    Image(systemName: library.previewingSoundID == sound.id
                          ? "stop.circle.fill" : "play.circle")
                        .font(.title3)
                        .foregroundStyle(MihrabColor.mint)
                }
                .buttonStyle(.borderless)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(
                    library.previewingSoundID == sound.id
                        ? L10n.adhStopPreview
                        : "\(L10n.adhPreview) \(sound.localizedName)"
                )
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .contain)
    }

    private func select(_ sound: AdhanSound) {
        switch target {
        case .all: library.setSound(sound, for: nil)
        case .prayer(let prayer): library.setSound(sound, for: prayer)
        }
        HapticsEngine.shared.light()
        Task { await NotificationEngine.shared.rescheduleAll() }
    }
}
