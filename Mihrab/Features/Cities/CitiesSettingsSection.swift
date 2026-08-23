import SwiftUI

/// Drop-in `Section` for the Settings `Form`. The main session embeds this.
struct CitiesSettingsSection: View {
    init() {}

    @State private var store = CityStore.shared
    @State private var showList = false

    var body: some View {
        Section {
            Button {
                HapticsEngine.shared.light()
                showList = true
            } label: {
                HStack {
                    Text(L10n.citiesTitle)
                    Spacer()
                    Text(store.activeCity?.name ?? L10n.citiesNoneSelected)
                        .foregroundStyle(MihrabColor.textSecondary)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                .frame(minHeight: MihrabSpace.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // A `.sheet` attached to a `Section` is dropped by `Form` — it has
            // to hang off a concrete row.
            .sheet(isPresented: $showList) { CityListView() }
            .accessibilityHint(L10n.citiesSettingsHint)

            if !store.isPremium {
                Text(L10n.citiesFreeTierNote(store.freeCityLimit))
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
        } header: {
            Text(L10n.citiesSectionTitle)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
        .task {
            store.syncCurrentLocationFromDevice()
            store.enforceTierOnLaunch()
        }
    }
}
