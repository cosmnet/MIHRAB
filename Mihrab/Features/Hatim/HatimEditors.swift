import SwiftUI

// MARK: - New individual hatim

struct HatimPlanEditor: View {
    @State private var store = HatimStore.shared
    @State private var title = L10n.hatimDefaultName
    @State private var target: Date = HatimPlanEditor.defaultTarget
    @Environment(\.dismiss) private var dismiss

    private static var defaultTarget: Date {
        HatimMath.endOfRamadan()
            ?? Calendar.current.date(byAdding: .day, value: 30, to: Date())
            ?? Date()
    }

    private var preview: HatimProgress {
        HatimMath.progress(
            for: HatimPlan(kind: .individual, title: title, scope: .fullMushaf, targetDate: target)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.hatimName, text: $title)
                        .frame(minHeight: MihrabSpace.hit)
                }

                Section {
                    DatePicker(
                        L10n.hatimFinishBy,
                        selection: $target,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .environment(\.locale, L10n.appLocale)

                    HStack(spacing: 10) {
                        ForEach(Self.presets, id: \.0) { label, date in
                            if let date {
                                Button(label) { target = date }
                                    .font(.caption.weight(.semibold))
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                    .frame(minHeight: MihrabSpace.hit)
                } header: {
                    Text(L10n.hatimFinishBy)
                } footer: {
                    if let perDay = preview.pagesPerDay {
                        Text("\(L10n.hatimDailyShareLabel): \(L10n.hatimDailyShare(perDay))")
                    }
                }
            }
            .navigationTitle(L10n.hatimNew)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.hatimCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.hatimCreate) {
                        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.add(
                            HatimPlan(
                                kind: .individual,
                                title: name.isEmpty ? L10n.hatimDefaultName : name,
                                scope: .fullMushaf,
                                targetDate: target
                            )
                        )
                        HapticsEngine.shared.success()
                        dismiss()
                    }
                }
            }
        }
    }

    private static var presets: [(String, Date?)] {
        let calendar = Calendar.current
        return [
            (L10n.hatimEndOfRamadan, HatimMath.endOfRamadan()),
            (L10n.hatimInThirtyDays, calendar.date(byAdding: .day, value: 30, to: Date())),
            (L10n.hatimInAYear, calendar.date(byAdding: .year, value: 1, to: Date()))
        ]
    }
}

// MARK: - Shared hatim

/// Organise or join. Both halves are local; the invite code *is* the protocol.
struct SharedHatimSheet: View {
    enum Route: String, CaseIterable, Identifiable {
        case organise, join
        var id: String { rawValue }
        var localizedName: String {
            self == .organise ? L10n.hatimSharedSetUp : L10n.hatimSharedJoin
        }
    }

    @State private var route: Route = .organise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $route) {
                    ForEach(Route.allCases) { route in
                        Text(route.localizedName).tag(route)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(16)

                switch route {
                case .organise: OrganiseHatimForm(onDone: { dismiss() })
                case .join: JoinHatimForm(onDone: { dismiss() })
                }
            }
            .background(MihrabBackdrop(ramadanMode: false).ignoresSafeArea())
            .navigationTitle(L10n.hatimShared)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.hatimCancel) { dismiss() }
                }
            }
        }
    }
}

// MARK: Organise

private struct OrganiseHatimForm: View {
    var onDone: () -> Void

    @State private var store = HatimStore.shared
    @State private var name = L10n.hatimShared
    @State private var shareCount = 30
    @State private var target: Date = HatimMath.endOfRamadan()
        ?? Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var myJuz: Set<Int> = []

    private var invite: HatimInvite {
        HatimInvite(
            groupID: groupID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? L10n.hatimShared
                : name.trimmingCharacters(in: .whitespacesAndNewlines),
            shareCount: shareCount,
            targetDate: target,
            organiser: nil
        )
    }

    /// Stable for the lifetime of this sheet so the code does not change under
    /// the organiser between reading it and sending it.
    @State private var groupID = HatimGroup.newID()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                honestyPanel

                field(L10n.hatimName) {
                    TextField(L10n.hatimName, text: $name)
                        .textFieldStyle(.plain)
                        .foregroundStyle(MihrabColor.textPrimary)
                }

                field(L10n.hatimShareCount) {
                    Picker("", selection: $shareCount) {
                        ForEach([5, 10, 15, 30], id: \.self) { n in
                            Text(L10n.hatimShareCountValue(n)).tag(n)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                field(L10n.hatimFinishBy) {
                    DatePicker("", selection: $target, in: Date()..., displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.locale, L10n.appLocale)
                }

                JuzPicker(selection: $myJuz, title: L10n.hatimPickJuz)

                ShareLink(item: invite.shareText()) {
                    Label(L10n.hatimInviteAction, systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
                }
                .buttonStyle(.borderedProminent)
                .tint(MihrabColor.emerald)

                Button {
                    guard !myJuz.isEmpty else { return }
                    store.joinShared(invite, claiming: Array(myJuz))
                    HapticsEngine.shared.success()
                    onDone()
                } label: {
                    Text(L10n.hatimCreate)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
                }
                .buttonStyle(.bordered)
                .tint(MihrabColor.mint)
                .disabled(myJuz.isEmpty)
            }
            .padding(16)
        }
    }

    private var honestyPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.hatimNoServerTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MihrabColor.textPrimary)
            Text(L10n.hatimNoServerBody)
                .font(.footnote)
                .foregroundStyle(MihrabColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
    }

    private func field<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).ornamentalCaps()
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
    }
}

// MARK: Join

private struct JoinHatimForm: View {
    var onDone: () -> Void

    @State private var store = HatimStore.shared
    @State private var code = ""
    @State private var invite: HatimInvite?
    @State private var failed = false
    @State private var myJuz: Set<Int> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.hatimCodeField).ornamentalCaps()
                    TextField(L10n.hatimCodeField, text: $code, axis: .vertical)
                        .lineLimit(2...5)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(MihrabColor.textPrimary)
                        .onChange(of: code) { _, new in
                            invite = HatimInvite.parse(new)
                            failed = !new.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                && invite == nil
                        }
                    if failed {
                        Text(L10n.hatimCodeInvalid)
                            .font(.caption)
                            .foregroundStyle(MihrabColor.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)

                if let invite {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(invite.name)
                            .font(.headline)
                            .foregroundStyle(MihrabColor.textPrimary)
                        Text(L10n.hatimShareCountValue(invite.shareCount))
                            .font(.caption)
                            .foregroundStyle(MihrabColor.textSecondary)
                        Text(
                            invite.targetDate.formatted(
                                Date.FormatStyle(date: .long, time: .omitted).locale(L10n.appLocale)
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)

                    JuzPicker(selection: $myJuz, title: L10n.hatimPickJuz)

                    Button {
                        guard !myJuz.isEmpty else { return }
                        store.joinShared(invite, claiming: Array(myJuz))
                        HapticsEngine.shared.success()
                        onDone()
                    } label: {
                        Text(L10n.hatimJoin)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MihrabColor.emerald)
                    .disabled(myJuz.isEmpty)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Juz picker

struct JuzPicker: View {
    @Binding var selection: Set<Int>
    let title: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).ornamentalCaps()
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...30, id: \.self) { juz in
                    Button {
                        HapticsEngine.shared.light()
                        if selection.contains(juz) { selection.remove(juz) } else { selection.insert(juz) }
                    } label: {
                        Text("\(juz)")
                            .font(.footnote.weight(.semibold).monospacedDigit())
                            .foregroundStyle(
                                selection.contains(juz) ? MihrabColor.abyss : MihrabColor.textSecondary
                            )
                            .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        selection.contains(juz)
                                            ? MihrabColor.mint
                                            : MihrabColor.abyss.opacity(0.35)
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(L10n.hatimJuzLabel(juz)))
                    .accessibilityAddTraits(selection.contains(juz) ? [.isSelected, .isButton] : .isButton)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius)
    }
}
