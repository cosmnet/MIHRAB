import Foundation

protocol APIClient: Sendable {
    func timings(date: Date, latitude: Double, longitude: Double,
                 method: CalculationMethod, madhab: Madhab) async throws -> DayPrayerTimes
    func calendar(year: Int, month: Int, latitude: Double, longitude: Double,
                  method: CalculationMethod, madhab: Madhab) async throws -> [DayPrayerTimes]
    func qiblaBearing(latitude: Double, longitude: Double) async throws -> Double
}

enum AladhanError: Error {
    case badURL, badResponse, decodingFailed
}

/// Aladhan API client — async/await, Codable DTOs, 50MB URLCache.
struct AladhanClient: APIClient {
    private let base = "https://api.aladhan.com/v1"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 8_000_000, diskCapacity: 50_000_000)
        config.timeoutIntervalForRequest = 15
        session = URLSession(configuration: config)
    }

    func timings(date: Date, latitude: Double, longitude: Double,
                 method: CalculationMethod, madhab: Madhab) async throws -> DayPrayerTimes {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.calendar = Calendar(identifier: .gregorian)
        let path = "\(base)/timings/\(formatter.string(from: date))"
        guard var components = URLComponents(string: path) else { throw AladhanError.badURL }
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "method", value: String(method.rawValue)),
            URLQueryItem(name: "school", value: String(madhab.rawValue)),
        ]
        guard let url = components.url else { throw AladhanError.badURL }
        let dto: TimingsResponse = try await fetch(url)
        return try dto.data.toDomain()
    }

    func calendar(year: Int, month: Int, latitude: Double, longitude: Double,
                  method: CalculationMethod, madhab: Madhab) async throws -> [DayPrayerTimes] {
        guard var components = URLComponents(string: "\(base)/calendar/\(year)/\(month)") else {
            throw AladhanError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "method", value: String(method.rawValue)),
            URLQueryItem(name: "school", value: String(madhab.rawValue)),
        ]
        guard let url = components.url else { throw AladhanError.badURL }
        let dto: CalendarResponse = try await fetch(url)
        return try dto.data.map { try $0.toDomain() }
    }

    func qiblaBearing(latitude: Double, longitude: Double) async throws -> Double {
        guard let url = URL(string: "\(base)/qibla/\(latitude)/\(longitude)") else {
            throw AladhanError.badURL
        }
        let dto: QiblaResponse = try await fetch(url)
        return dto.data.direction
    }

    private func fetch<T: Decodable>(_ url: URL, retries: Int = 2) async throws -> T {
        var lastError: Error = AladhanError.badResponse
        for attempt in 0...retries {
            do {
                let (data, response) = try await session.data(from: url)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw AladhanError.badResponse
                }
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                lastError = error
                if attempt < retries {
                    try await Task.sleep(for: .seconds(pow(2.0, Double(attempt))))
                }
            }
        }
        throw lastError
    }
}

// MARK: - DTOs

private struct TimingsResponse: Decodable { let data: TimingsData }
private struct CalendarResponse: Decodable { let data: [TimingsData] }
private struct QiblaResponse: Decodable {
    struct QiblaData: Decodable { let direction: Double }
    let data: QiblaData
}

private struct TimingsData: Decodable {
    let timings: [String: String]
    let date: DateInfo

    struct DateInfo: Decodable {
        let hijri: HijriInfo?
        let gregorian: GregorianInfo?
        struct HijriInfo: Decodable {
            let day: String
            let month: MonthInfo
            let year: String
            struct MonthInfo: Decodable { let number: Int; let en: String; let ar: String }
        }
        struct GregorianInfo: Decodable { let date: String } // "dd-MM-yyyy"
    }

    func toDomain() throws -> DayPrayerTimes {
        let map: [Prayer: String] = [
            .fajr: "Fajr", .sunrise: "Sunrise", .dhuhr: "Dhuhr",
            .asr: "Asr", .maghrib: "Maghrib", .isha: "Isha",
        ]
        var result: [Prayer: Date] = [:]
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = .current

        // Anchor to the API-returned Gregorian date, not "now", so
        // month-calendar responses land on the correct day.
        var dayDate = calendar.startOfDay(for: Date())
        if let g = date.gregorian?.date {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "dd-MM-yyyy"
            dayFormatter.calendar = Calendar(identifier: .gregorian)
            dayFormatter.timeZone = .current
            if let parsed = dayFormatter.date(from: g) {
                dayDate = calendar.startOfDay(for: parsed)
            }
        }
        for (prayer, key) in map {
            guard let raw = timings[key] else { throw AladhanError.decodingFailed }
            // API may append " (TRT)" style suffixes — take HH:mm prefix.
            let clean = String(raw.prefix(5))
            guard let parsed = timeFormatter.date(from: clean) else { throw AladhanError.decodingFailed }
            let comps = calendar.dateComponents([.hour, .minute], from: parsed)
            let dayStart = calendar.startOfDay(for: Date())
            guard let combined = calendar.date(bySettingHour: comps.hour ?? 0,
                                               minute: comps.minute ?? 0,
                                               second: 0, of: dayStart) else {
                throw AladhanError.decodingFailed
            }
            result[prayer] = combined
            dayDate = dayStart
        }

        // Correctness: verify ordering Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha.
        let ordered = Prayer.allCases.compactMap { result[$0] }
        guard ordered == ordered.sorted() else { throw AladhanError.decodingFailed }

        var hijri: HijriDate?
        if let h = date.hijri, let day = Int(h.day), let year = Int(h.year) {
            hijri = HijriDate(day: day, month: h.month.number, year: year,
                              monthNameEn: h.month.en, monthNameAr: h.month.ar)
        }
        return DayPrayerTimes(date: dayDate, times: result, hijriDate: hijri)
    }
}
