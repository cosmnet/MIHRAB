import AVFoundation
import XCTest

@testable import Mihrab

/// The shipped call to prayer.
///
/// A missing or wrongly-encoded adhan is invisible until Fajr, on a real device,
/// in someone's bedroom — the worst possible place to discover it. These checks
/// run against the built bundle, so they fail in CI instead.
final class AdhanAssetTests: XCTestCase {

    private static let fullName = "mihrab-ezan.caf"
    private static let shortName = "mihrab-ezan-short.caf"

    private func bundledURL(_ name: String) throws -> URL {
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        let url = Bundle(for: Self.self).url(forResource: base, withExtension: ext)
            ?? Bundle.main.url(forResource: base, withExtension: ext)
        return try XCTUnwrap(url, "\(name) is not in the bundle")
    }

    func testBothRecordingsShip() throws {
        _ = try bundledURL(Self.fullName)
        _ = try bundledURL(Self.shortName)
    }

    /// `UNNotificationSound` plays only linear PCM, MA4 (IMA4), µ-law or a-law
    /// inside caf/aiff/wav. Anything else silently falls back to the default
    /// tone — the failure mode this project exists to avoid.
    func testEncodingIsOneNotificationCenterCanPlay() throws {
        let playable: Set<AudioFormatID> = [
            kAudioFormatLinearPCM,
            kAudioFormatAppleIMA4,
            kAudioFormatULaw,
            kAudioFormatALaw,
        ]
        for name in [Self.fullName, Self.shortName] {
            let file = try AVAudioFile(forReading: try bundledURL(name))
            let format = file.fileFormat.streamDescription.pointee.mFormatID
            XCTAssertTrue(
                playable.contains(format),
                "\(name) is encoded as \(format), which UNNotificationSound cannot play"
            )
            XCTAssertEqual(file.fileFormat.channelCount, 1, "\(name) should be mono")
            XCTAssertEqual(file.fileFormat.sampleRate, 44_100, accuracy: 1, "\(name) sample rate")
        }
    }

    /// iOS truncates a notification sound at 30 s no matter how long the file
    /// is. The short edit exists precisely so the notification path gets a
    /// deliberate ending rather than a cut-off mid-word.
    func testShortEditFitsTheThirtySecondNotificationLimit() throws {
        let url = try bundledURL(Self.shortName)
        let duration = try XCTUnwrap(AdhanFileStore.duration(of: url))
        XCTAssertLessThanOrEqual(duration, 30.0, "the short edit would be cut off")
        XCTAssertGreaterThan(duration, 20.0, "too short to be recognisable as the adhan")
    }

    /// The alarm route is the whole reason AlarmKit is used: it plays the
    /// recording in full, past the notification limit.
    func testFullRecordingIsActuallyFullLength() throws {
        let url = try bundledURL(Self.fullName)
        let duration = try XCTUnwrap(AdhanFileStore.duration(of: url))
        XCTAssertGreaterThan(duration, 120.0, "a real adhan runs minutes, not seconds")
    }

    /// `mihrab-tone-` is reserved for the generated tones; a recording using
    /// that prefix would be skipped by bundle discovery and never appear.
    func testRecordingsDoNotUseTheReservedTonePrefix() {
        for name in [Self.fullName, Self.shortName] {
            XCTAssertFalse(name.hasPrefix("mihrab-tone-"), "\(name) uses the reserved prefix")
        }
    }
}
