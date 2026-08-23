import SwiftUI

/// Drop-in `Section` for the Settings `Form`. The main session embeds this.
struct QadaSettingsSection: View {
    init() {}

    @State private var store = QadaStore.shared
    @State private var showTracker = false
    @State private var confirmReset = false

    var body: some View {
        Section {
            Button {
                HapticsEngine.shared.light()
                showTracker = true
            } label: {
                HStack {
                    Text(L10n.qadaTitle)
                    Spacer()
                    Text(store.isSetUp ? L10n.qadaRemainingCount(store.totalRemaining) : L10n.qadaSettingsNone)
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
            .sheet(isPresented: $showTracker) { QadaView() }
            .accessibilityHint(L10n.qadaSettingsHint)

            if store.isSetUp {
                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Text(L10n.qadaReset)
                        .frame(minHeight: MihrabSpace.hit)
                }
                .confirmationDialog(
                    L10n.qadaReset,
                    isPresented: $confirmReset,
                    titleVisibility: .visible
                ) {
                    Button(L10n.qadaReset, role: .destructive) {
                        store.reset()
                        HapticsEngine.shared.warning()
                    }
                    Button(L10n.qadaCancel, role: .cancel) {}
                } message: {
                    Text(L10n.qadaResetConfirm)
                }
            }
        } header: {
            Text(L10n.qadaSectionTitle)
        } footer: {
            Text(L10n.qadaSubtitle)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }
}
