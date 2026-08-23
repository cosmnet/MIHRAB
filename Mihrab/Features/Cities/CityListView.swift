import CoreLocation
import SwiftUI

/// Manage the city list: add, remove, reorder, activate.
///
/// Search reuses `CitySearch` from `Features/Onboarding/ManualCityPicker.swift`
/// (preset list + `CLGeocoder`). That helper is already actor-safe: it never
/// lets a `CLPlacemark` cross a boundary — it maps to `OnboardingCity`, which
/// is `Sendable` — so nothing here has to re-implement geocoding.
struct CityListView: View {
    init() {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var store = CityStore.shared
    @State private var subscriptions = SubscriptionManager.shared
    @State private var locationManager = LocationManager.shared

    @State private var query = ""
    @State private var remoteResults: [OnboardingCity] = []
    @State private var isSearching = false
    @State private var showPaywall = false
    @State private var errorMessage: String?
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop().ignoresSafeArea()

                List {
                    savedSection
                    if !store.isPremium { upgradeSection }
                    searchSection
                }
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            }
            .navigationTitle(L10n.citiesTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: L10n.citiesSearchPlaceholder)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.done) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? L10n.citiesDoneEditing : L10n.citiesEdit) {
                        withAnimation(reduceMotion ? .none : MihrabMotion.snappyAnimation) {
                            isEditing.toggle()
                        }
                    }
                    .disabled(store.storedCities.isEmpty)
                }
            }
            .onChange(of: query) { _, _ in remoteResults = [] }
            .task {
                store.syncCurrentLocationFromDevice()
                store.enforceTierOnLaunch()
            }
            .onChange(of: locationManager.cityName) { _, _ in
                store.syncCurrentLocationFromDevice()
            }
            .sheet(isPresented: $showPaywall) { PaywallView(source: .feature) }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Saved cities

    private var savedSection: some View {
        Section {
            if store.cities.isEmpty {
                Text(L10n.citiesEmpty)
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
            ForEach(store.cities) { city in
                cityRow(city)
            }
            .onDelete { store.remove(atOffsets: $0) }
            .onMove { store.move(fromOffsets: $0, toOffset: $1) }
        } header: {
            Text(L10n.citiesSectionSaved)
        } footer: {
            if let message = errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(MihrabColor.danger)
            } else if let remaining = store.remainingSlots {
                Text(L10n.citiesFreeTierFooter(store.freeCityLimit, remaining: remaining))
                    .font(.caption)
                    .foregroundStyle(MihrabColor.textSecondary)
            }
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    private func cityRow(_ city: SavedCity) -> some View {
        let isActive = store.activeCity?.id == city.id
        let locked = store.isLocked(city)
        return Button {
            if locked {
                HapticsEngine.shared.warning()
                showPaywall = true
            } else {
                HapticsEngine.shared.success()
                errorMessage = nil
                store.activate(city)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: city.isCurrentLocation ? "location.fill" : "building.2.fill")
                    .foregroundStyle(isActive ? MihrabColor.mint : MihrabColor.textTertiary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .font(.body)
                        .foregroundStyle(MihrabColor.textPrimary)
                    if let region = city.region, !region.isEmpty {
                        Text(region)
                            .font(.caption)
                            .foregroundStyle(MihrabColor.textSecondary)
                    }
                }

                Spacer(minLength: 0)

                if locked {
                    PremiumLockBadge(compact: true)
                } else if isActive {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(MihrabColor.mint)
                }
            }
            .frame(minHeight: MihrabSpace.hit)
            .contentShape(Rectangle())
            .opacity(locked ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(locked ? L10n.premiumLockedHint : L10n.citiesActivateHint)
    }

    // MARK: - Upgrade nudge

    private var upgradeSection: some View {
        Section {
            Button {
                HapticsEngine.shared.light()
                showPaywall = true
            } label: {
                HStack(spacing: 10) {
                    PremiumLockBadge()
                    Text(L10n.citiesUpgradePrompt)
                        .font(.footnote)
                        .foregroundStyle(MihrabColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: MihrabSpace.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    // MARK: - Search / add

    private var presetResults: [OnboardingCity] {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? []
            : CitySearch.filteredPresets(query)
    }

    private var searchSection: some View {
        Section(L10n.citiesSectionAdd) {
            if presetResults.isEmpty && remoteResults.isEmpty {
                Text(L10n.citiesSearchHint)
                    .font(.footnote)
                    .foregroundStyle(MihrabColor.textSecondary)
            }

            ForEach(presetResults) { candidate in
                addRow(candidate)
            }
            ForEach(remoteResults) { candidate in
                addRow(candidate)
            }

            Button {
                Task { await runSearch() }
            } label: {
                HStack(spacing: 8) {
                    if isSearching {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(L10n.citiesSearchAction)
                }
                .frame(minHeight: MihrabSpace.hit)
            }
            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || isSearching)
        }
        .listRowBackground(MihrabColor.moss.opacity(0.72))
    }

    private func addRow(_ candidate: OnboardingCity) -> some View {
        Button {
            add(candidate)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(MihrabColor.mint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(candidate.name)
                        .foregroundStyle(MihrabColor.textPrimary)
                    if !candidate.region.isEmpty {
                        Text(candidate.region)
                            .font(.caption)
                            .foregroundStyle(MihrabColor.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                if !store.canAddMore() { PremiumLockBadge(compact: true) }
            }
            .frame(minHeight: MihrabSpace.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(candidate.name), \(candidate.region)")
        .accessibilityHint(L10n.citiesAddHint)
    }

    private func add(_ candidate: OnboardingCity) {
        let city = SavedCity(
            name: candidate.name,
            latitude: candidate.latitude,
            longitude: candidate.longitude,
            region: candidate.region.isEmpty ? nil : candidate.region
        )
        do {
            try store.add(city)
            HapticsEngine.shared.success()
            errorMessage = nil
            store.activate(city)
            query = ""
            remoteResults = []
        } catch CityStoreError.limitReached {
            HapticsEngine.shared.warning()
            showPaywall = true
        } catch {
            HapticsEngine.shared.warning()
            errorMessage = error.localizedDescription
        }
    }

    private func runSearch() async {
        isSearching = true
        // `CitySearch.geocode` is nonisolated and returns `Sendable` values only.
        let found = await CitySearch.geocode(query)
        remoteResults = found
        isSearching = false
        if found.isEmpty { HapticsEngine.shared.warning() }
    }
}

#Preview {
    CityListView()
}
