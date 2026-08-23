import SwiftUI

/// Drop-in `Section` for the Settings `Form`. The main session embeds this.
struct ZakatSettingsSection: View {
    init() {}

    @State private var store = ZakatStore.shared
    @State private var showCalculator = false

    var body: some View {
        Section {
            Button {
                HapticsEngine.shared.light()
                showCalculator = true
            } label: {
                HStack {
                    Text(L10n.zakatTitle)
                    Spacer()
                    Text(anniversaryLabel)
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
            // A `.sheet` on a `Section` is dropped by `Form` — hang it off a row.
            .sheet(isPresented: $showCalculator) { ZakatView() }
            .accessibilityHint(L10n.zakatSettingsHint)
        } header: {
            Text(L10n.zakatSectionTitle)
        } footer: {
            Text(L10n.zakatDisclaimer)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    private var anniversaryLabel: String {
        guard let next = store.nextZakatAnniversary else { return L10n.zakatSettingsNoYear }
        return ZakatView.dateFormatter.string(from: next)
    }
}
