import SwiftUI

/// Calendar source + per-prayer corrections, ready to be embedded in
/// `SettingsView`'s `Form` (see `AGENT_BRIEF_W1.md` rule 5).
///
/// The copy is deliberately unglamorous: three Turkish calendar traditions
/// genuinely disagree, and a worship app should say so plainly rather than
/// imply one is "correct".
struct PrayerSourceSettingsSection: View {
    @State private var preferences = PrayerSourcePreferences.shared
    @State private var repository = PrayerTimesRepository.shared

    init() {}

    var body: some View {
        Section {
            Picker(L10n.sourceSectionTitle, selection: Binding(
                get: { preferences.source },
                set: { newValue in
                    preferences.source = newValue
                    HapticsEngine.shared.light()
                    Task { await repository.refresh() }
                }
            )) {
                ForEach(PrayerSource.allCases) { source in
                    Text(source.localizedName).tag(source)
                }
            }
            .accessibilityHint(L10n.sourceSectionFooter)

            Text(preferences.source.localizedExplanation)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if preferences.source.isTurkishTradition {
                Text(L10n.sourceTurkeyOnlyNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            NavigationLink {
                PrayerOffsetsView()
            } label: {
                LabeledContent(L10n.offsetsTitle) {
                    Text(preferences.hasOffsets ? offsetSummary : L10n.offsetMinutes(0))
                        .foregroundStyle(.secondary)
                }
            }

            if repository.isUsingOfflineEngine {
                Label(L10n.timesOfflineBadge, systemImage: "iphone.gen3")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(L10n.timesOfflineExplanation)
            }
        } header: {
            Text(L10n.sourceSectionTitle)
        } footer: {
            Text(L10n.sourceSectionFooter)
                .fixedSize(horizontal: false, vertical: true)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    private var offsetSummary: String {
        let count = preferences.offsets.filter { $0.value != 0 }.count
        guard count > 0 else { return L10n.offsetMinutes(0) }
        if count == 1, let entry = preferences.offsets.first(where: { $0.value != 0 }) {
            return "\(entry.key.localizedName) \(L10n.offsetMinutes(entry.value))"
        }
        return "\(count)"
    }
}

/// ±minute correction per prayer (roadmap #8). Stored in
/// `PrayerSourcePreferences`, not `AppSettings`.
struct PrayerOffsetsView: View {
    @State private var preferences = PrayerSourcePreferences.shared
    @State private var repository = PrayerTimesRepository.shared

    init() {}

    var body: some View {
        Form {
            Section {
                ForEach(Prayer.allCases) { prayer in
                    row(for: prayer)
                }
            } footer: {
                Text(L10n.offsetsFooter)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if preferences.hasOffsets {
                Section {
                    Button(role: .destructive) {
                        preferences.resetOffsets()
                        HapticsEngine.shared.warning()
                        Task { await repository.refresh() }
                    } label: {
                        Text(L10n.offsetsReset)
                    }
                    .frame(minHeight: 44)
                }
            }
        }
        .navigationTitle(L10n.offsetsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(for prayer: Prayer) -> some View {
        let value = preferences.offset(for: prayer)
        return Stepper(
            value: Binding(
                get: { preferences.offset(for: prayer) },
                set: { newValue in
                    preferences.setOffset(newValue, for: prayer)
                    HapticsEngine.shared.light()
                    Task { await repository.refresh() }
                }
            ),
            in: PrayerSourcePreferences.offsetRange
        ) {
            HStack {
                Label(prayer.localizedName, systemImage: prayer.symbolName)
                    .labelStyle(.titleAndIcon)
                Spacer(minLength: MihrabSpace.unit)
                Text(L10n.offsetMinutes(value))
                    .monospacedDigit()
                    .foregroundStyle(value == 0 ? .secondary : .primary)
            }
        }
        .frame(minHeight: 44)
        .accessibilityLabel(prayer.localizedName)
        .accessibilityValue(L10n.offsetAccessibilityValue(prayer, value))
    }
}
