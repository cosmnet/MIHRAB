import Foundation

/// The definition of a shared hatim, small enough to travel inside a message.
///
/// **There is no server.** An invite is the whole protocol: the organiser
/// encodes the hatim (name, target date, how many shares) into a short code,
/// sends it however people already talk — WhatsApp, a family group, a mosque
/// board — and each participant pastes it back in and picks their juz. From
/// then on every device tracks only its own reading, offline.
///
/// What that honestly does **not** give you: nobody can see who has claimed
/// what, or how far anyone else has got. Two people can pick juz 7 and neither
/// device will know. The UI states this instead of drawing a group ring it
/// cannot fill. Making it real needs a shared backend — see the agent report.
struct HatimInvite: Codable, Hashable, Sendable {
    var groupID: String
    var name: String
    var shareCount: Int
    var targetDate: Date
    var organiser: String?
    /// Format version, so a future code shape can be rejected cleanly instead
    /// of decoding into nonsense.
    var v: Int = 1

    static let currentVersion = 1
    static let scheme = "revak"
    static let host = "hatim"

    // MARK: Encoding

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// Base64url, no padding — safe in a URL, a QR code and a chat message.
    var code: String? {
        guard let data = try? Self.encoder.encode(self) else { return nil }
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// `mihrab://hatim?c=…`
    var url: URL? {
        guard let code else { return nil }
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.queryItems = [URLQueryItem(name: "c", value: code)]
        return components.url
    }

    // MARK: Decoding

    /// Accepts a bare code, a `mihrab://hatim?c=…` URL, or a message that
    /// merely *contains* either — people paste whole WhatsApp lines.
    static func parse(_ input: String) -> HatimInvite? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let invite = decode(trimmed) { return invite }

        if let url = URL(string: trimmed), let invite = parse(url: url) { return invite }

        // Scan the text for something that decodes.
        for token in trimmed.split(whereSeparator: { $0.isWhitespace || $0 == "\n" }) {
            let candidate = String(token)
            if let invite = decode(candidate) { return invite }
            if let url = URL(string: candidate), let invite = parse(url: url) { return invite }
        }
        return nil
    }

    static func parse(url: URL) -> HatimInvite? {
        guard url.scheme?.lowercased() == scheme,
              url.host()?.lowercased() == host,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "c" })?.value
        else { return nil }
        return decode(code)
    }

    private static func decode(_ code: String) -> HatimInvite? {
        var normalised = code
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Restore base64 padding.
        let remainder = normalised.count % 4
        if remainder > 0 { normalised += String(repeating: "=", count: 4 - remainder) }

        guard let data = Data(base64Encoded: normalised),
              let invite = try? decoder.decode(HatimInvite.self, from: data),
              invite.v == currentVersion,
              (2...30).contains(invite.shareCount),
              !invite.name.isEmpty,
              invite.name.count <= 80
        else { return nil }
        return invite
    }

    // MARK: Share text

    /// The message the organiser sends. Written to be forwarded as-is: it says
    /// what the hatim is, when it ends, and exactly what to do with the code.
    func shareText() -> String {
        let day = targetDate.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted).locale(L10n.appLocale)
        )
        let link = url?.absoluteString ?? code ?? ""
        return L10n.hatimInviteMessage(name: name, shares: shareCount, date: day, link: link)
    }
}
