import AppIntents

/// The seven phrases Siri, Spotlight and the Shortcuts app learn on install.
///
/// Rules Apple enforces here, all of them load-bearing:
/// * at most **10** shortcuts per app — seven leaves room to grow;
/// * every phrase must contain `\(.applicationName)`, otherwise the whole
///   provider is dropped at build time;
/// * phrases must be literals, so the tr/en/ar wordings are listed side by side
///   rather than resolved through `L10n` (which runs too late to be indexed).
struct MihrabAppShortcuts: AppShortcutsProvider {

    static var shortcutTileColor: ShortcutTileColor { .teal }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextPrayerIntent(),
            phrases: [
                "Next prayer in \(.applicationName)",
                "When is the next prayer in \(.applicationName)",
                "\(.applicationName) sonraki namaz",
                "\(.applicationName) bir sonraki namaz ne zaman",
                "\(.applicationName) الوقت التالي للصلاة",
            ],
            shortTitle: "Next Prayer",
            systemImageName: "moon.stars.fill"
        )

        AppShortcut(
            intent: TodayPrayerTimesIntent(),
            phrases: [
                "Today's prayer times in \(.applicationName)",
                "\(.applicationName) bugünün namaz vakitleri",
                "\(.applicationName) مواقيت الصلاة اليوم",
            ],
            shortTitle: "Prayer Times",
            systemImageName: "clock.fill"
        )

        AppShortcut(
            intent: QiblaDirectionIntent(),
            phrases: [
                "Qibla direction in \(.applicationName)",
                "Which way is the Qibla in \(.applicationName)",
                "\(.applicationName) kıble yönü",
                "\(.applicationName) kıble ne tarafta",
                "\(.applicationName) اتجاه القبلة",
            ],
            shortTitle: "Qibla",
            systemImageName: "location.north.circle.fill"
        )

        AppShortcut(
            intent: AddDhikrIntent(),
            phrases: [
                "Count dhikr in \(.applicationName)",
                "Add a dhikr in \(.applicationName)",
                "\(.applicationName) zikir say",
                "\(.applicationName) zikir ekle",
                "\(.applicationName) عدّ الذكر",
            ],
            shortTitle: "Count Dhikr",
            systemImageName: "circle.grid.3x3.fill"
        )

        AppShortcut(
            intent: StartDhikrSessionIntent(),
            phrases: [
                "Start a dhikr session in \(.applicationName)",
                "\(.applicationName) zikir seti başlat",
                "\(.applicationName) ابدأ جلسة ذكر",
            ],
            shortTitle: "Dhikr Session",
            systemImageName: "circle.hexagongrid.fill"
        )

        AppShortcut(
            intent: MarkPrayerPrayedIntent(),
            phrases: [
                "Mark a prayer as prayed in \(.applicationName)",
                "I prayed in \(.applicationName)",
                "\(.applicationName) namazı kıldım",
                "\(.applicationName) namazı kılındı işaretle",
                "\(.applicationName) سجل أداء الصلاة",
            ],
            shortTitle: "I Prayed",
            systemImageName: "checkmark.seal.fill"
        )

        AppShortcut(
            intent: OpenMihrabIntent(),
            phrases: [
                "Open \(.applicationName)",
                "\(.applicationName) aç",
                "افتح \(.applicationName)",
            ],
            shortTitle: "Open Mihrab",
            systemImageName: "moon.fill"
        )
    }
}
