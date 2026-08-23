import SwiftUI

/// Drop-in `Section` for the Settings `Form`. The main session embeds this.
///
/// It exists mostly to carry the ±1 day honesty note somewhere permanent, and
/// to give the full calendar a second door.
struct CalendarSettingsSection: View {
    init() {}

    @State private var showCalendar = false

    private var next: Observance? { IslamicCalendar.nextOccurrences().first }

    var body: some View {
        Section {
            Button {
                HapticsEngine.shared.light()
                showCalendar = true
            } label: {
                HStack {
                    Text(L10n.calendarTitle)
                    Spacer()
                    Text(next?.localizedName ?? "—")
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
            .sheet(isPresented: $showCalendar) { ReligiousCalendarView() }
            .accessibilityHint(L10n.calendarSubtitle)
        } header: {
            Text(L10n.calendarTitle)
        } footer: {
            Text(L10n.calendarAccuracyNote)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }
}
