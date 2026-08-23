import AppIntents
import SwiftUI

// MARK: - Next prayer

/// "Hey Siri, bir sonraki namaz ne zaman?"
///
/// Reads the App Group cache only — it never launches the app, never touches
/// the network, and answers on the Lock Screen in well under a second.
struct NextPrayerIntent: AppIntent {

    static var title: LocalizedStringResource { "Next Prayer" }

    static var description: IntentDescription {
        IntentDescription("Tells you which prayer is next and how long is left.")
    }

    /// `ForegroundContinuableIntent` is deprecated; this is the replacement.
    /// The intent runs in the background and only pulls the app forward when
    /// the system decides the result wants a full screen.
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    static let isDiscoverable = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog & ShowsSnippetView {
        let now = Date()
        guard let next = MihrabIntentData.nextPrayer(after: now) else {
            throw MihrabIntentError.noSchedule
        }
        let clock = MihrabIntentData.clock(next.date)
        let remaining = MihrabIntentData.remaining(from: now, to: next.date)
        let spoken = L10n.intNextPrayerAnswer(
            prayer: next.prayer.localizedNamazName,
            clock: clock,
            remaining: remaining
        )
        return .result(
            value: spoken,
            dialog: IntentDialog(.mihrab(spoken)),
            view: NextPrayerSnippet(prayer: next.prayer, time: next.date, city: MihrabIntentData.cityName)
        )
    }
}

struct NextPrayerSnippet: View {
    let prayer: Prayer
    let time: Date
    var city: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: prayer.symbolName)
                .font(.title2)
                .foregroundStyle(MihrabColor.brass)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(prayer.localizedNamazName)
                    .font(.headline)
                Text(MihrabIntentData.clock(time))
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(MihrabColor.mint)
                if let city {
                    Text(city)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text(L10n.intRemainingCaption)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary)
                CountdownText(to: time)
                    .font(.body.monospacedDigit())
            }
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Today's times

/// Returns today's schedule as entities, so Shortcuts users can loop over them,
/// filter them, or feed one into `MarkPrayerPrayedIntent`.
struct TodayPrayerTimesIntent: AppIntent {

    static var title: LocalizedStringResource { "Today's Prayer Times" }

    static var description: IntentDescription {
        IntentDescription("Returns every prayer time for today.")
    }

    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    static let isDiscoverable = true

    func perform() async throws -> some IntentResult & ReturnsValue<[PrayerEntity]> & ShowsSnippetView {
        guard let day = MihrabIntentData.day() else { throw MihrabIntentError.noSchedule }
        let entities = Prayer.allCases.map { PrayerEntity(prayer: $0, time: day.time(for: $0)) }
        return .result(value: entities, view: TodayTimesSnippet(day: day, city: MihrabIntentData.cityName))
    }
}

struct TodayTimesSnippet: View {
    let day: DayPrayerTimes
    var city: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(city ?? "Mihrab")
                    .font(.headline)
                Spacer()
                if let hijri = day.hijriDate {
                    Text(hijri.formatted)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                }
            }
            ForEach(Prayer.allCases) { prayer in
                HStack {
                    Image(systemName: prayer.symbolName)
                        .font(.caption)
                        .frame(width: 18)
                        .foregroundStyle(MihrabColor.brass)
                    Text(prayer.localizedName)
                        .font(.subheadline)
                    Spacer()
                    Text(day.time(for: prayer).map { MihrabIntentData.clock($0) } ?? "—")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(MihrabColor.mint)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
    }
}

// MARK: - Qibla

/// "Kıble ne tarafta?" — answers from the last known coordinate, and says
/// plainly when there is none rather than pointing at nothing.
struct QiblaDirectionIntent: AppIntent {

    static var title: LocalizedStringResource { "Qibla Direction" }

    static var description: IntentDescription {
        IntentDescription("Gives the compass bearing to the Kaaba from your saved location.")
    }

    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    static let isDiscoverable = true

    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog & ShowsSnippetView {
        guard let coordinate = MihrabIntentData.coordinate else {
            throw MihrabIntentError.noLocation
        }
        let bearing = QiblaMath.bearing(fromLatitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = QiblaMath.distanceToMakkah(
            fromLatitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        let compass = L10n.intCompassPoint(Int((bearing / 45).rounded()))
        let spoken = L10n.intQiblaAnswer(
            degrees: Int(bearing.rounded()),
            compass: compass,
            distance: Int(distance.rounded())
        )
        return .result(
            value: bearing,
            dialog: IntentDialog(.mihrab(spoken)),
            view: QiblaSnippet(bearing: bearing, distance: distance, compass: compass)
        )
    }
}

struct QiblaSnippet: View {
    let bearing: Double
    let distance: Double
    let compass: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(MihrabColor.textTertiary.opacity(0.4), lineWidth: 2)
                Image(systemName: "location.north.fill")
                    .font(.title3)
                    .foregroundStyle(MihrabColor.emerald)
                    .rotationEffect(.degrees(bearing))
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(bearing.rounded()))° \(compass)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(MihrabColor.mint)
                Text(L10n.intQiblaDistanceCaption)
                    .font(.caption2)
                    .foregroundStyle(MihrabColor.textSecondary)
                Text("\(Int(distance.rounded())) km")
                    .font(.subheadline.monospacedDigit())
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L10n.intQiblaTitle) \(Int(bearing.rounded())) \(compass)")
    }
}
