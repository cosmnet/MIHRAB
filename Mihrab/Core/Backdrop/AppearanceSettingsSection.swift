import SwiftUI

/// Drop-in `Section`s for the Settings `Form`: background intensity, card
/// texture, the counter's motif (chosen from live tiles, not a list of names),
/// accent colour, theme mode and the Ramadan skin.
struct AppearanceSettingsSection: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {}

    private let rowBackground = MihrabColor.moss.opacity(0.72)

    var body: some View {
        Group {
            backgroundSection
            textureSection
            colourSection
        }
    }

    // MARK: - Background

    private var backgroundSection: some View {
        Section {
            Picker(L10n.apprIntensity, selection: Binding(
                get: { settings.backdropIntensity },
                set: {
                    settings.backdropIntensity = $0
                    HapticsEngine.shared.light()
                }
            )) {
                ForEach(AppSettings.BackdropIntensity.allCases) { level in
                    Text(level.localizedName).tag(level)
                }
            }
            .pickerStyle(.segmented)

            intensityPreview
        } header: {
            Text(L10n.apprBackdropSection)
        } footer: {
            Text(L10n.apprIntensityFooter)
                .font(.caption)
                .foregroundStyle(MihrabColor.textSecondary)
        }
        .listRowBackground(rowBackground)
    }

    /// A live strip of the calm backdrop so the segmented control has a
    /// consequence you can see without leaving the screen.
    private var intensityPreview: some View {
        CalmBackdrop(
            surface: .today,
            ramadanMode: false,
            intensity: settings.backdropIntensity
        )
        .frame(height: 76)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MihrabColor.mint.opacity(0.16), lineWidth: 1)
        }
        .overlay {
            Text(L10n.apprPreviewHint)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MihrabColor.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(MihrabColor.abyss.opacity(0.55), in: Capsule())
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .accessibilityHidden(true)
    }

    // MARK: - Texture

    private var textureSection: some View {
        Section {
            Toggle(L10n.apprCardTexture, isOn: Binding(
                get: { settings.cardTextureEnabled },
                set: {
                    settings.cardTextureEnabled = $0
                    HapticsEngine.shared.light()
                }
            ))

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.apprDhikrMotif)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                    spacing: 12
                ) {
                    ForEach(ShaderMotif.allCases) { motif in
                        motifTile(motif)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(L10n.apprTextureSection)
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.apprCardTextureFooter)
                Text(L10n.apprDhikrMotifFooter)
            }
            .font(.caption)
            .foregroundStyle(MihrabColor.textSecondary)
        }
        .listRowBackground(rowBackground)
    }

    private func motifTile(_ motif: ShaderMotif) -> some View {
        let selected = settings.dhikrShaderMotif == motif && settings.dhikrShaderStyle != .none
        return Button {
            settings.dhikrShaderMotif = motif
            HapticsEngine.shared.light()
        } label: {
            VStack(spacing: 7) {
                ShaderMotifPreview(
                    motif: motif,
                    isSelected: selected,
                    accent: settings.accentTheme.color
                )
                .frame(height: 62)

                Text(motif.localizedName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(selected ? MihrabColor.textPrimary : MihrabColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : MihrabMotion.snappyAnimation, value: selected)
        .accessibilityLabel(motif.localizedName)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Colour & theme

    private var colourSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.accentColor)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MihrabColor.textPrimary)

                HStack(spacing: 16) {
                    ForEach(AppSettings.AccentTheme.allCases) { option in
                        accentSwatch(option)
                    }
                    Spacer(minLength: 0)
                }
                // The palette is what the paywall calls "themes"; the emerald
                // default stays free, the alternates are the Plus layer.
                .premiumRequired(.themes)
            }
            .padding(.vertical, 2)

            Picker(L10n.settingsTheme, selection: Binding(
                get: { settings.themeMode },
                set: { settings.themeMode = $0 }
            )) {
                Text(L10n.themeAuto).tag(AppSettings.ThemeMode.auto)
                Text(L10n.themeDark).tag(AppSettings.ThemeMode.dark)
                Text(L10n.themeLight).tag(AppSettings.ThemeMode.light)
            }

            Toggle(L10n.ramadanTheme, isOn: Binding(
                get: { settings.ramadanThemeEnabled },
                set: { settings.ramadanThemeEnabled = $0 }
            ))
        } header: {
            Text(L10n.apprColourSection)
        }
        .listRowBackground(rowBackground)
    }

    private func accentSwatch(_ option: AppSettings.AccentTheme) -> some View {
        let selected = settings.accentTheme == option
        return Button {
            settings.accentTheme = option
            HapticsEngine.shared.light()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [option.secondary, option.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)

                Circle()
                    .strokeBorder(
                        selected ? MihrabColor.textPrimary.opacity(0.9) : MihrabColor.mint.opacity(0.22),
                        lineWidth: selected ? 2 : 1
                    )
                    .frame(width: 34, height: 34)

                if selected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.black))
                        .foregroundStyle(MihrabColor.abyss)
                }
            }
            // 44pt target without a 44pt dot.
            .frame(width: MihrabSpace.hit, height: MihrabSpace.hit)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : MihrabMotion.snappyAnimation, value: selected)
        .accessibilityLabel(option.localizedName)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}
