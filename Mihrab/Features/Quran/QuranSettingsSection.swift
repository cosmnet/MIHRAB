import SwiftUI

/// Drop-in `Section` for the Settings `Form`. The main session embeds this.
///
/// Covers both roadmap items in one row each: the reader and the hatim. Neither
/// is gated — the footer says so, because "the foundation of worship is always
/// free" only counts if the app repeats it where money is being discussed.
struct QuranSettingsSection: View {
    init() {}

    @State private var bookmarks = QuranBookmarkStore.shared
    @State private var hatim = HatimStore.shared
    @State private var showReader = false
    @State private var showLicence = false

    var body: some View {
        Section {
            Button {
                HapticsEngine.shared.light()
                showReader = true
            } label: {
                HStack {
                    Text(L10n.quranTitle)
                    Spacer()
                    if let resume = bookmarks.resume,
                       let sura = QuranCatalog.sura(resume.ref.sura) {
                        Text("\(sura.localizedName) \(resume.ref.citation)")
                            .foregroundStyle(MihrabColor.textSecondary)
                            .lineLimit(1)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                .frame(minHeight: MihrabSpace.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // A `.sheet` on a `Section` is dropped by `Form` — hang it off a row.
            .sheet(isPresented: $showReader) { QuranView() }
            .accessibilityHint(L10n.quranSettingsHint)

            if let plan = hatim.primaryPlan {
                let progress = hatim.progress(for: plan)
                HStack {
                    Text(L10n.hatimTitle)
                    Spacer()
                    Text(L10n.hatimPercent(progress.percent))
                        .foregroundStyle(MihrabColor.textSecondary)
                        .monospacedDigit()
                }
                .frame(minHeight: MihrabSpace.hit)
            }

            if bookmarks.streak > 0 {
                HStack {
                    Text(L10n.quranStreakLabel)
                    Spacer()
                    Text(L10n.quranStreakDays(bookmarks.streak))
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                .frame(minHeight: MihrabSpace.hit)
            }

            Button {
                showLicence = true
            } label: {
                HStack {
                    Text(L10n.quranTextSource)
                    Spacer()
                    Text("Tanzil · CC BY 3.0")
                        .foregroundStyle(MihrabColor.textSecondary)
                        .font(.footnote)
                }
                .frame(minHeight: MihrabSpace.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showLicence) { QuranLicenceView() }
        } header: {
            Text(L10n.quranSectionTitle)
        } footer: {
            Text("\(L10n.quranSettingsHint)")
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }
}
