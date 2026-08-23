import SwiftUI
import UIKit

/// The shareable imsakiye.
///
/// In Turkey the month table is not a power-user feature — it is the thing
/// people screenshot and send to family every Ramadan. So it gets a real
/// poster layout with the city, the tradition it was produced from, and the
/// religious days marked, rather than a screenshot of a scroll view.
struct ImsakiyeCard: View {
    let days: [DayPrayerTimes]
    let monthDate: Date
    let cityName: String
    let sourceName: String
    let methodName: String

    private let columns: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]

    /// Fixed width, so this is the one place in the app where absolute point
    /// sizes are correct: the output is an image, not a Dynamic Type surface.
    static let renderWidth: CGFloat = 820

    var body: some View {
        VStack(spacing: 0) {
            header
            table
            footer
        }
        .frame(width: Self.renderWidth)
        .background(MihrabColor.abyss)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("MIHRAB")
                .font(.system(size: 15, weight: .medium))
                .tracking(6)
                .foregroundStyle(MihrabColor.brass)

            Text(L10n.tmxImsakiyeTitle)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(MihrabColor.textPrimary)

            Text(monthDate.formatted(.dateTime.month(.wide).year().locale(L10n.appLocale)))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MihrabColor.mint)

            if !cityName.isEmpty {
                Label(cityName, systemImage: "location.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(MihrabColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 34)
        .padding(.bottom, 22)
    }

    private var table: some View {
        VStack(spacing: 3) {
            headerRow
            Rectangle()
                .fill(MihrabColor.brass.opacity(0.45))
                .frame(height: 1)
                .padding(.bottom, 3)
            ForEach(days) { row($0) }
        }
        .padding(.horizontal, 28)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text(L10n.day)
                .frame(width: 86, alignment: .leading)
            ForEach(columns) { prayer in
                Text(prayer.shortName)
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(MihrabColor.brass)
        .padding(.vertical, 6)
    }

    private func row(_ day: DayPrayerTimes) -> some View {
        let calendar = Calendar.current
        let isFriday = calendar.component(.weekday, from: day.date) == 6
        let isRamadan = day.hijriDate?.isRamadan ?? false
        let sacred = day.hijriDate.flatMap(SacredDayLookup.day(for:))

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    Text(day.date, format: .dateTime.day())
                        .font(.system(size: 15, weight: isFriday ? .bold : .regular).monospacedDigit())
                    Text(day.date.formatted(.dateTime.weekday(.abbreviated).locale(L10n.appLocale)))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(isFriday ? MihrabColor.brass : MihrabColor.textTertiary)
                }
                .frame(width: 86, alignment: .leading)

                ForEach(columns) { prayer in
                    Text(day.time(for: prayer)?.formatted(date: .omitted, time: .shortened) ?? "–")
                        .font(.system(size: 15, weight: isFriday ? .semibold : .regular).monospacedDigit())
                        .frame(maxWidth: .infinity)
                }
            }
            .foregroundStyle(isFriday ? MihrabColor.textPrimary : MihrabColor.textSecondary)

            if let sacred {
                HStack(spacing: 5) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 9))
                    Text(sacred.localizedName)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(MihrabColor.brass)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 86)
                .padding(.top, 1)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background {
            if sacred != nil {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MihrabColor.brass.opacity(0.16))
            } else if isRamadan {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MihrabColor.ramadanViolet.opacity(0.45))
            } else if isFriday {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MihrabColor.moss.opacity(0.7))
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 3) {
            Rectangle()
                .fill(MihrabColor.mint.opacity(0.18))
                .frame(height: 1)
                .padding(.bottom, 10)
            Text("\(sourceName) · \(methodName)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MihrabColor.textSecondary)
            Text(L10n.tmxComputedOnDevice)
                .font(.system(size: 11))
                .foregroundStyle(MihrabColor.textTertiary)
        }
        .padding(.horizontal, 28)
        .padding(.top, 18)
        .padding(.bottom, 30)
    }
}

/// Maps a Hijri date onto the bundled religious-day table.
/// Reads `BundledContent` only — that file belongs to another agent.
enum SacredDayLookup {
    static func day(for hijri: HijriDate) -> ReligiousDay? {
        BundledContent.religiousDays.first {
            $0.hijriMonth == hijri.month && $0.hijriDay == hijri.day
        }
    }
}

/// Renders the card once, off the view's `body`, and hands back a
/// `ShareImage`. Rendering inside a `ShareLink` initialiser re-rasterises the
/// whole month on every layout pass — see the note in `MonthlyTimesView`.
@MainActor
enum ImsakiyeRenderer {
    static func render(days: [DayPrayerTimes],
                       monthDate: Date,
                       cityName: String,
                       sourceName: String,
                       methodName: String) -> UIImage? {
        guard !days.isEmpty else { return nil }
        let renderer = ImageRenderer(content:
            ImsakiyeCard(days: days,
                         monthDate: monthDate,
                         cityName: cityName,
                         sourceName: sourceName,
                         methodName: methodName)
        )
        renderer.scale = 2
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
