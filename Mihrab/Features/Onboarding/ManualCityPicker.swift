import CoreLocation
import SwiftUI

/// A city the user can pick without granting location access.
struct OnboardingCity: Identifiable, Hashable, Sendable {
    var id: String { "\(name)-\(latitude)-\(longitude)" }
    let name: String
    let region: String
    let latitude: Double
    let longitude: Double
    /// IANA zone, carried so a saved city is never rendered on the device's
    /// clock. `nil` only when the geocoder could not say.
    var timeZoneIdentifier: String? = nil
}

/// Geocoding kept off the main actor — only `Sendable` values cross back.
enum CitySearch {
    static let presets: [OnboardingCity] = [
        OnboardingCity(name: "İstanbul", region: "Türkiye", latitude: 41.0082, longitude: 28.9784, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Ankara", region: "Türkiye", latitude: 39.9334, longitude: 32.8597, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "İzmir", region: "Türkiye", latitude: 38.4237, longitude: 27.1428, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Bursa", region: "Türkiye", latitude: 40.1826, longitude: 29.0665, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Antalya", region: "Türkiye", latitude: 36.8969, longitude: 30.7133, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Adana", region: "Türkiye", latitude: 37.0000, longitude: 35.3213, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Konya", region: "Türkiye", latitude: 37.8746, longitude: 32.4932, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Gaziantep", region: "Türkiye", latitude: 37.0662, longitude: 37.3833, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Kayseri", region: "Türkiye", latitude: 38.7312, longitude: 35.4787, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Trabzon", region: "Türkiye", latitude: 41.0027, longitude: 39.7168, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Diyarbakır", region: "Türkiye", latitude: 37.9144, longitude: 40.2306, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Erzurum", region: "Türkiye", latitude: 39.9043, longitude: 41.2679, timeZoneIdentifier: "Europe/Istanbul"),
        OnboardingCity(name: "Mekke", region: "Suudi Arabistan", latitude: 21.3891, longitude: 39.8579, timeZoneIdentifier: "Asia/Riyadh"),
        OnboardingCity(name: "Medine", region: "Suudi Arabistan", latitude: 24.5247, longitude: 39.5692, timeZoneIdentifier: "Asia/Riyadh"),
        OnboardingCity(name: "Kudüs", region: "Filistin", latitude: 31.7683, longitude: 35.2137, timeZoneIdentifier: "Asia/Jerusalem"),
        OnboardingCity(name: "Kahire", region: "Mısır", latitude: 30.0444, longitude: 31.2357, timeZoneIdentifier: "Africa/Cairo"),
        OnboardingCity(name: "Dubai", region: "BAE", latitude: 25.2048, longitude: 55.2708, timeZoneIdentifier: "Asia/Dubai"),
        OnboardingCity(name: "Londra", region: "Birleşik Krallık", latitude: 51.5074, longitude: -0.1278, timeZoneIdentifier: "Europe/London"),
        OnboardingCity(name: "Berlin", region: "Almanya", latitude: 52.5200, longitude: 13.4050, timeZoneIdentifier: "Europe/Berlin"),
        OnboardingCity(name: "Paris", region: "Fransa", latitude: 48.8566, longitude: 2.3522, timeZoneIdentifier: "Europe/Paris"),
        OnboardingCity(name: "Amsterdam", region: "Hollanda", latitude: 52.3676, longitude: 4.9041, timeZoneIdentifier: "Europe/Amsterdam"),
        OnboardingCity(name: "New York", region: "ABD", latitude: 40.7128, longitude: -74.0060, timeZoneIdentifier: "America/New_York"),
        OnboardingCity(name: "Kuala Lumpur", region: "Malezya", latitude: 3.1390, longitude: 101.6869, timeZoneIdentifier: "Asia/Kuala_Lumpur"),
        OnboardingCity(name: "Jakarta", region: "Endonezya", latitude: -6.2088, longitude: 106.8456, timeZoneIdentifier: "Asia/Jakarta"),
    ]

    static func filteredPresets(_ query: String) -> [OnboardingCity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return presets }
        return presets.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.region.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// Nonisolated on purpose: `CLPlacemark` never crosses an actor boundary.
    static func geocode(_ query: String) async -> [OnboardingCity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        let geocoder = CLGeocoder()
        guard let placemarks = try? await geocoder.geocodeAddressString(trimmed) else { return [] }
        return placemarks.compactMap { placemark in
            guard let coordinate = placemark.location?.coordinate else { return nil }
            let name = placemark.locality ?? placemark.name ?? trimmed
            let region = [placemark.administrativeArea, placemark.country]
                .compactMap { $0 }
                .joined(separator: ", ")
            return OnboardingCity(
                name: name,
                region: region,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                // `CLPlacemark` is not Sendable, but its zone's identifier is.
                timeZoneIdentifier: placemark.timeZone?.identifier
            )
        }
    }
}

/// Manual location fallback for people who would rather not share GPS.
struct ManualCityPicker: View {
    var onSelect: (OnboardingCity) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var remoteResults: [OnboardingCity] = []
    @State private var isSearching = false

    private var presetResults: [OnboardingCity] { CitySearch.filteredPresets(query) }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabColor.abyss.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(presetResults) { city in
                            row(city)
                        }

                        if !remoteResults.isEmpty {
                            Text(L10n.obCitySearchAction)
                                .ornamentalCaps()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 12)
                            ForEach(remoteResults) { city in
                                row(city)
                            }
                        }

                        if presetResults.isEmpty && remoteResults.isEmpty {
                            VStack(spacing: 12) {
                                Text(L10n.obCitySearchEmpty)
                                    .font(.subheadline)
                                    .foregroundStyle(MihrabColor.textSecondary)
                                    .multilineTextAlignment(.center)
                                searchButton
                            }
                            .padding(.top, 40)
                        } else {
                            searchButton.padding(.top, 12)
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(L10n.obCityPickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: L10n.obCitySearchPlaceholder)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.done) { dismiss() }
                }
            }
            .onChange(of: query) { _, _ in remoteResults = [] }
        }
        .preferredColorScheme(.dark)
    }

    private var searchButton: some View {
        Button {
            Task { await runSearch() }
        } label: {
            HStack(spacing: 8) {
                if isSearching {
                    ProgressView().tint(MihrabColor.mint)
                } else {
                    Image(systemName: "magnifyingglass")
                }
                Text(L10n.obCitySearchAction)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(MihrabColor.mint)
            .frame(maxWidth: .infinity)
            .frame(minHeight: MihrabSpace.hit)
            .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
        }
        .buttonStyle(.plain)
        .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || isSearching)
    }

    private func row(_ city: OnboardingCity) -> some View {
        Button {
            HapticsEngine.shared.success()
            onSelect(city)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(MihrabColor.mint.opacity(0.8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                    if !city.region.isEmpty {
                        Text(city.region)
                            .font(.caption)
                            .foregroundStyle(MihrabColor.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MihrabColor.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: MihrabSpace.hit)
            .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(city.name), \(city.region)")
    }

    private func runSearch() async {
        isSearching = true
        let found = await CitySearch.geocode(query)
        remoteResults = found
        isSearching = false
        if found.isEmpty { HapticsEngine.shared.warning() }
    }
}
