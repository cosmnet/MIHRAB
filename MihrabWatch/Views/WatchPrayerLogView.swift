import SwiftUI

/// "I prayed this", from the wrist.
///
/// Five rows, one tap each. The mark is written to the watch's own store
/// immediately and queued for the phone with `transferUserInfo`, so it survives
/// the phone being out of range — the row is already ticked, and the phone
/// catches up when the two devices next meet. Nothing here waits on
/// reachability, and nothing here shows a spinner.
///
/// Sunrise is absent on purpose: it is a marker in the day, not a prayer to log.
struct WatchPrayerLogView: View {

    @Environment(WatchAppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    header
                    rows
                }
                .padding(.horizontal, 2)
            }
            .navigationTitle(L10n.wLog)
            .containerBackground(WatchPalette.timesGradient, for: .navigation)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.wLogProgress(model.loggedCount, WatchAppModel.fardPrayers.count))
                .font(.headline.monospacedDigit())
                .foregroundStyle(MihrabColor.sprout)
            Text(L10n.wLogPrompt)
                .font(.caption2)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var rows: some View {
        VStack(spacing: 6) {
            ForEach(WatchAppModel.fardPrayers) { prayer in
                let logged = model.isLogged(prayer)
                Button {
                    model.toggleLog(prayer)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: logged ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(logged ? MihrabColor.emerald : MihrabColor.textTertiary)
                        Text(prayer.localizedNamazName)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 4)
                        if let time = model.schedule?.today.time(for: prayer) {
                            Text(WatchScheduleBuilder.clock(time))
                                .monospacedDigit()
                                .foregroundStyle(MihrabColor.textTertiary)
                        }
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 7)
                .padding(.horizontal, 9)
                .background(logged ? WatchPalette.highlight : WatchPalette.card,
                            in: .rect(cornerRadius: 11))
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(logged ? [.isSelected, .isButton] : .isButton)
            }
        }
    }
}
