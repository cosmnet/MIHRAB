import SwiftUI

struct EsmaGridView: View {
    var featured: EsmaName?
    @Binding var query: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selected: EsmaName?
    @State private var appeared = false

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !trimmedQuery.isEmpty }

    private var filtered: [(offset: Int, element: EsmaName)] {
        let all = Array(BundledContent.esma.enumerated())
        guard isSearching else { return all }
        return all.filter {
            $0.element.transliteration.localizedCaseInsensitiveContains(trimmedQuery)
                || $0.element.en.localizedCaseInsensitiveContains(trimmedQuery)
                || $0.element.tr.localizedCaseInsensitiveContains(trimmedQuery)
                || $0.element.arabic.contains(trimmedQuery)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
                .padding(.bottom, 18)

            Text(isSearching ? L10n.esmaResultCount(filtered.count) : L10n.esmaNinetyNine)
                .ornamentalCaps()
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            if let featured, !isSearching {
                featuredEntry(featured)
                    .padding(.bottom, 4)
            }

            dictionaryList
        }
        .onAppear { withAnimation { appeared = true } }
        .sheet(item: $selected) { name in
            EsmaDetailSheet(name: name)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(MihrabColor.textTertiary)
            TextField(L10n.searchEsma, text: $query)
                .textFieldStyle(.plain)
                .foregroundStyle(MihrabColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if isSearching {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(MihrabColor.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.clear))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: MihrabSpace.hit)
        .background(Capsule().fill(MihrabColor.moss))
        .overlay {
            Capsule().strokeBorder(MihrabColor.mint.opacity(0.28), lineWidth: 1)
        }
    }

    private func featuredEntry(_ name: EsmaName) -> some View {
        let number = (BundledContent.esma.firstIndex(where: { $0.id == name.id }) ?? 0) + 1
        return Button { selected = name } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.nameOfTheDay)
                    .ornamentalCaps()
                EsmaDictionaryRow(number: number, name: name, arabicSize: 36)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mihrabCardScene("esma-bg", opacity: 0.4)
            .mihrabCard(interactive: true)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(name.transliteration))
    }

    @ViewBuilder
    private var dictionaryList: some View {
        if filtered.isEmpty {
            MihrabEmptyState(
                symbol: "magnifyingglass",
                title: L10n.esmaNoResults,
                message: L10n.esmaNoResultsBody
            )
            .padding(.top, 20)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(filtered, id: \.element.id) { index, name in
                    Button { selected = name } label: {
                        EsmaDictionaryRow(number: index + 1, name: name, arabicSize: 34)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, -16)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared || reduceMotion ? 0 : 10)
                    .animation(
                        reduceMotion
                            ? .easeInOut(duration: 0.2)
                            : MihrabMotion.standardAnimation.delay(Double(min(index, 20)) * 0.02),
                        value: appeared
                    )

                    if index != filtered.last?.offset {
                        MihrabHairline()
                            .padding(.horizontal, -16)
                    }
                }
            }
        }
    }
}

struct EsmaDictionaryRow: View {
    let number: Int
    let name: EsmaName
    var arabicSize: CGFloat = 38

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(String(format: "%02d", number))
                    .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(MihrabColor.brass)
                    .frame(width: 36, alignment: .leading)

                Spacer(minLength: 8)

                Text(name.arabic)
                    .font(MihrabFont.arabic(arabicSize))
                    .foregroundStyle(MihrabColor.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .lineSpacing(6)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            Text(name.localizedMeaning)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(MihrabColor.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 48)

            Text(name.transliteration)
                .font(.caption.weight(.medium))
                .foregroundStyle(MihrabColor.textTertiary)
                .padding(.leading, 48)
        }
        .accessibilityElement(children: .combine)
    }
}

struct EsmaDetailSheet: View {
    let name: EsmaName
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var number: Int {
        (BundledContent.esma.firstIndex(where: { $0.id == name.id }) ?? 0) + 1
    }

    private var otherLanguageMeaning: String {
        L10n.isTurkish ? name.en : name.tr
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                MihrabOrnament(name: "esma-ornament", opacity: 0.09, side: 340)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 48)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(String(format: "%02d  ·  99", number))
                            .ornamentalCaps()

                        Text(name.arabic)
                            .font(MihrabFont.arabic(64))
                            .foregroundStyle(MihrabColor.textPrimary)
                            .multilineTextAlignment(.trailing)
                            .lineSpacing(12)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                            .padding(.top, 8)

                        Text(name.localizedMeaning)
                            .font(.system(size: 34, weight: .semibold, design: .default))
                            .foregroundStyle(MihrabColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(name.transliteration)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(MihrabColor.brass)

                        Capsule()
                            .fill(MihrabColor.brass.opacity(0.45))
                            .frame(width: 48, height: 1)
                            .padding(.vertical, 4)

                        Text(otherLanguageMeaning)
                            .font(MihrabFont.quote(22))
                            .foregroundStyle(MihrabColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(L10n.esmaReflection(name.localizedMeaning))
                            .font(MihrabFont.quoteItalic(19))
                            .foregroundStyle(MihrabColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                NavigationLink {
                    DhikrView()
                } label: {
                    Text(L10n.recite100)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(MihrabColor.emerald))
                        .shadow(color: MihrabColor.emerald.opacity(reduceMotion ? 0 : 0.22), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(MihrabColor.abyss.opacity(0.001))
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
        .presentationBackground(.ultraThinMaterial)
    }
}
