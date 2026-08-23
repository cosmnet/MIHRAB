import SwiftUI

/// The counter's phrase picker: classics, ready-made routines, the Names, and
/// whatever the user has written themselves.
struct DhikrLibrarySheet: View {
    let onPick: (DhikrItem) -> Void
    let onStartRoutine: (DhikrRoutine) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var store = DhikrStore.shared
    @State private var query = ""
    @State private var showComposer = false
    @State private var showPaywall = false
    @State private var pendingDelete: DhikrItem?

    private var accent: Color { theme.accent }

    private var isPremium: Bool { SubscriptionManager.shared.hasAccess(to: .dhikrUnlimitedGoals) }

    private func matches(_ item: DhikrItem) -> Bool {
        guard !query.isEmpty else { return true }
        let needle = query.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        return [item.localizedName, item.transliteration, item.arabic, item.meaning]
            .contains { $0.folding(options: .diacriticInsensitive, locale: .current).lowercased().contains(needle) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .sheet, ramadanMode: theme.isRamadanMode)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 26) {
                        if query.isEmpty {
                            routineSection
                        }
                        section(title: L10n.dhkLibraryPhrases, items: DhikrCatalog.core + DhikrCatalog.extended)
                        section(title: L10n.dhkLibraryEsma, items: DhikrCatalog.esma)
                        customSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationTitle(L10n.dhkLibrary)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: Text(L10n.search))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                        .foregroundStyle(MihrabColor.textPrimary)
                }
            }
            .tint(accent)
        }
        .presentationBackground(.ultraThinMaterial)
        .sheet(isPresented: $showComposer) {
            DhikrComposerSheet { title, arabic, target in
                let item = store.addCustom(title: title, arabic: arabic, target: target)
                onPick(item)
                dismiss()
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView(source: .feature) }
        .confirmationDialog(
            L10n.dhkDelete,
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button(L10n.dhkDelete, role: .destructive) {
                if let pendingDelete { store.removeCustom(pendingDelete) }
                pendingDelete = nil
            }
            Button(L10n.dhkCancel, role: .cancel) { pendingDelete = nil }
        } message: {
            Text(pendingDelete?.localizedName ?? "")
        }
    }

    // MARK: - Sections

    private func sectionHeader(_ title: String, trailing: AnyView? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).ornamentalCaps()
            Spacer()
            if let trailing { trailing }
        }
    }

    @ViewBuilder
    private func section(title: String, items: [DhikrItem]) -> some View {
        let visible = items.filter(matches)
        if !visible.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(title)
                ForEach(visible) { item in
                    phraseRow(item)
                }
            }
        }
    }

    private var routineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(L10n.dhkLibraryRoutines)
            ForEach(DhikrCatalog.routines) { routine in
                Button {
                    DhikrFeedback.light()
                    onStartRoutine(routine)
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(MihrabColor.brass.opacity(0.16))
                                .frame(width: 42, height: 42)
                            Image(systemName: "list.bullet.rectangle.portrait.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(MihrabColor.brass)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(routine.localizedTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MihrabColor.textPrimary)
                            Text(routine.localizedSubtitle)
                                .font(.caption)
                                .foregroundStyle(MihrabColor.textSecondary)
                        }
                        Spacer(minLength: 6)
                        Text(L10n.dhkRoutineTotal(routine.totalCount))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(MihrabColor.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius, fill: MihrabColor.moss.opacity(0.85))
                }
                .pressable(reduceMotion)
                .accessibilityLabel(Text("\(routine.localizedTitle), \(L10n.dhkRoutineTotal(routine.totalCount))"))
            }
        }
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                L10n.dhkLibraryCustom,
                trailing: AnyView(
                    HStack(spacing: 8) {
                        if !isPremium { PremiumLockBadge(compact: true) }
                        Button {
                            if isPremium {
                                showComposer = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            Label(L10n.dhkNewCustom, systemImage: "plus.circle.fill")
                                .font(.caption.weight(.semibold))
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(accent)
                        .frame(minHeight: MihrabSpace.hit)
                    }
                )
            )

            let visible = store.customItems.filter(matches)
            if visible.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.dhkCustomEmpty)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                    Text(L10n.dhkCustomEmptyBody)
                        .font(.caption)
                        .foregroundStyle(MihrabColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius, fill: MihrabColor.moss.opacity(0.55))
            } else {
                ForEach(visible) { item in
                    phraseRow(item)
                        .contextMenu {
                            Button(role: .destructive) {
                                pendingDelete = item
                            } label: {
                                Label(L10n.dhkDelete, systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private func phraseRow(_ item: DhikrItem) -> some View {
        Button {
            DhikrFeedback.phraseSwap()
            onPick(item)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.localizedName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MihrabColor.textPrimary)
                        .lineLimit(1)
                    if !item.meaning.isEmpty {
                        Text(item.meaning)
                            .font(.caption)
                            .foregroundStyle(MihrabColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                if !item.arabic.isEmpty {
                    Text(item.arabic)
                        .font(MihrabFont.arabic(19))
                        .foregroundStyle(MihrabColor.sprout)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: 150, alignment: .trailing)
                }
                Text(L10n.dhkTargetLabel(item.target))
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(MihrabColor.brass)
                    .frame(minWidth: 40, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: MihrabSpace.hit, alignment: .leading)
            .mihrabSolidCard(cornerRadius: MihrabSpace.rowRadius, fill: MihrabColor.moss.opacity(0.72))
        }
        .pressable(reduceMotion)
        .accessibilityLabel(Text(item.localizedName))
        .accessibilityValue(Text(L10n.dhkTargetLabel(item.target)))
    }
}

// MARK: - Composer

/// Create a dhikr of your own: wording, optional Arabic, and a target.
struct DhikrComposerSheet: View {
    let onSave: (String, String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(Theme.self) private var theme

    @State private var title = ""
    @State private var arabic = ""
    @State private var target = 33

    private let suggestions = [11, 33, 66, 99, 100, 313, 500, 1000]

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MihrabBackdrop(surface: .sheet, ramadanMode: theme.isRamadanMode)
                Form {
                    Section {
                        TextField(L10n.dhkCustomName, text: $title)
                            .textInputAutocapitalization(.words)
                        TextField(L10n.dhkCustomArabic, text: $arabic)
                            .font(MihrabFont.arabic(20))
                            .multilineTextAlignment(L10n.isArabic ? .leading : .trailing)
                    }
                    .listRowBackground(MihrabColor.moss.opacity(0.72))

                    Section(L10n.dhkCustomTarget) {
                        Stepper(value: $target, in: 0...10_000, step: 1) {
                            Text(L10n.dhkTargetLabel(target))
                                .monospacedDigit()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { value in
                                    Button {
                                        target = value
                                    } label: {
                                        Text("\(value)")
                                            .font(.caption.weight(.semibold).monospacedDigit())
                                            .padding(.horizontal, 14)
                                            .frame(height: 34)
                                            .foregroundStyle(target == value ? Color.white : MihrabColor.textSecondary)
                                            .background {
                                                Capsule().fill(
                                                    target == value
                                                        ? theme.accent.opacity(0.9)
                                                        : MihrabColor.abyss.opacity(0.35)
                                                )
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listRowBackground(MihrabColor.moss.opacity(0.72))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(L10n.dhkNewCustom)
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.accent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.dhkCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.dhkSave) {
                        onSave(title, arabic, target)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
    }
}
