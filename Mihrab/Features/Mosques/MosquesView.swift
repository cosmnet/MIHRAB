import MapKit
import SwiftUI

struct Mosque: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let distance: CLLocationDistance
    let phone: String?
    let mapItem: MKMapItem

    static func == (lhs: Mosque, rhs: Mosque) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var distanceText: String {
        distance < 1000
            ? "\(Int(distance)) m"
            : String(format: "%.1f km", distance / 1000)
    }

    var walkingMinutes: Int { Int(distance / 80) } // ~80 m/min
}

@Observable
final class MosqueSearchModel {
    private(set) var mosques: [Mosque] = []
    private(set) var isSearching = false

    @MainActor
    func search(center: CLLocationCoordinate2D) async {
        isSearching = true
        defer { isSearching = false }

        var results: [Mosque] = []
        var seen = Set<String>()

        let queries: [MKLocalSearch.Request] = [
            {
                let r = MKLocalSearch.Request()
                r.naturalLanguageQuery = "mosque"
                r.region = MKCoordinateRegion(center: center, latitudinalMeters: 5000, longitudinalMeters: 5000)
                return r
            }(),
            {
                let r = MKLocalSearch.Request()
                r.naturalLanguageQuery = "camii"
                r.region = MKCoordinateRegion(center: center, latitudinalMeters: 5000, longitudinalMeters: 5000)
                return r
            }(),
            {
                let r = MKLocalSearch.Request()
                r.naturalLanguageQuery = "masjid"
                r.region = MKCoordinateRegion(center: center, latitudinalMeters: 5000, longitudinalMeters: 5000)
                return r
            }(),
        ]

        for request in queries {
            if let response = try? await MKLocalSearch(request: request).start() {
                for item in response.mapItems {
                    let name = item.name ?? "Mosque"
                    let key = "\(name)-\(Int(item.location.coordinate.latitude * 1000))-\(Int(item.location.coordinate.longitude * 1000))"
                    guard !seen.contains(key) else { continue }
                    seen.insert(key)
                    let distance = item.location.distance(from: CLLocation(latitude: center.latitude,
                                                                           longitude: center.longitude))
                    results.append(Mosque(name: name, coordinate: item.location.coordinate,
                                          distance: distance, phone: item.phoneNumber, mapItem: item))
                }
            }
        }
        mosques = results.sorted { $0.distance < $1.distance }
    }
}

struct MosquesView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss
    @State private var model = MosqueSearchModel()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selected: Mosque?
    @State private var showSearchAreaChip = false

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $selected) {
                UserAnnotation()
                ForEach(model.mosques) { mosque in
                    Annotation(mosque.name, coordinate: mosque.coordinate) {
                        MosquePin(isSelected: selected == mosque)
                    }
                    .tag(mosque)
                }
            }
            .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onMapCameraChange { _ in showSearchAreaChip = true }
            .overlay(alignment: .top) {
                if showSearchAreaChip {
                    Button {
                        if let center = locationManager.effectiveCoordinate {
                            Task { await model.search(center: center) }
                        }
                        showSearchAreaChip = false
                    } label: {
                        Label(L10n.msqSearchArea, systemImage: "magnifyingglass")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .glassEffect(.regular.interactive(), in: .capsule)
                    }
                    .padding(.top, 8)
                }
            }
            .overlay(alignment: .bottom) {
                mosqueList
            }
            .navigationTitle(L10n.msqTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
        .task {
            if let center = locationManager.effectiveCoordinate {
                cameraPosition = .region(MKCoordinateRegion(
                    center: center, latitudinalMeters: 4000, longitudinalMeters: 4000))
                await model.search(center: center)
            }
        }
    }

    private var mosqueList: some View {
        VStack(spacing: 0) {
            if isFriday {
                Label(L10n.msqJumuahToday, systemImage: "star.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MihrabColor.brass)
                    .padding(.top, 10)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if model.isSearching && model.mosques.isEmpty {
                        ProgressView()
                            .tint(MihrabColor.mint)
                            .padding(24)
                    } else if model.mosques.isEmpty {
                        Text(L10n.msqNoneFound)
                            .font(.subheadline)
                            .foregroundStyle(MihrabColor.textSecondary)
                            .padding(20)
                    } else {
                        ForEach(model.mosques.prefix(15)) { mosque in
                            mosqueCard(mosque)
                        }
                    }
                }
                .padding()
            }
        }
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var isFriday: Bool {
        Calendar.current.component(.weekday, from: Date()) == 6
    }

    private func mosqueCard(_ mosque: Mosque) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(mosque.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            HStack(spacing: 8) {
                Label(mosque.distanceText, systemImage: "figure.walk")
                Text("· " + L10n.msqWalkMinutes(mosque.walkingMinutes))
            }
            .font(.caption)
            .foregroundStyle(MihrabColor.textSecondary)
            HStack(spacing: 8) {
                Button {
                    mosque.mapItem.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking,
                    ])
                } label: {
                    Label(L10n.msqDirections, systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(MihrabColor.emerald)

                if mosque.phone != nil, let url = URL(string: "tel://\(mosque.phone ?? "")") {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Image(systemName: "phone.fill")
                            .frame(minWidth: 28, minHeight: 28)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(Text(L10n.msqCall))
                }
            }
        }
        .padding(14)
        .frame(width: 240, alignment: .leading)
        .mihrabCard(cornerRadius: 20)
        .onTapGesture {
            selected = mosque
            withAnimation(MihrabMotion.standardAnimation) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: mosque.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000))
            }
        }
    }
}

private struct MosquePin: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(MihrabColor.forest.opacity(0.9))
                .frame(width: isSelected ? 44 : 34, height: isSelected ? 44 : 34)
                .overlay {
                    Circle()
                        .strokeBorder(isSelected ? MihrabColor.brass : MihrabColor.emerald,
                                      lineWidth: isSelected ? 2.5 : 1.5)
                }
            Image(systemName: "moon.fill")
                .font(.system(size: isSelected ? 18 : 13))
                .foregroundStyle(isSelected ? MihrabColor.brass : MihrabColor.mint)
        }
        .shadow(color: MihrabColor.emerald.opacity(0.4), radius: 6)
        .animation(MihrabMotion.snappyAnimation, value: isSelected)
    }
}
