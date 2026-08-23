# Mihrab — adhan & alert sounds

This folder is where **licensed adhan recordings** go. It ships empty on
purpose: nobody on the engineering side can lawfully add a muezzin's recording,
so the app is built to work with none, work better with yours, and never fake
one in between.

What the app already has without any file here:

* three **synthesised, royalty-free tones** (brass bell, two-tone gong, dawn
  chime) generated on device on first launch — they are struck-metal timbres,
  never an imitation of the human call to prayer;
* **silent (vibrate only)** and **system default**;
* **user import** — anyone can bring their own recording in from Files.

## Dropping a recording in

1. Copy the file into this folder (`Mihrab/Resources/Audio/`).
2. Add it to the **Mihrab** app target's *Copy Bundle Resources* build phase.
   (The project does not use synchronized folders, so this step is manual.)
3. Build. **No code change is needed** — `AdhanLibrary.reload()` enumerates the
   bundle at launch via `AdhanFileStore.bundledFileNames()` and every audio file
   it finds becomes a selectable sound.

### Naming

The **file name is the label** shown in Settings. `AdhanLibrary.displayName(fromFileBaseName:)`
replaces `-` and `_` with spaces and capitalises each word:

| File | Shows up as |
| --- | --- |
| `mekke-ezani.caf` | "Mekke Ezani" |
| `medine_sabah.m4a` | "Medine Sabah" |
| `istanbul-fajr.caf` | "Istanbul Fajr" |

Two reserved conventions:

* names beginning `mihrab-tone-` are reserved for the generated tones and are
  skipped by bundle discovery;
* nothing else is reserved — but keep names ASCII, lowercase and hyphenated so
  `UNNotificationSound` can find them reliably.

Fajr traditionally carries its own call, so shipping a separate `*-fajr` file is
worth doing; Settings lets each prayer pick its own sound.

### Format

| | Recommended | Also accepted |
| --- | --- | --- |
| Container | **CAF** | `m4a`, `wav`, `aiff`, `aif`, `mp3` |
| Encoding | 16-bit linear PCM | AAC (m4a), MP3 |
| Sample rate | **44 100 Hz** | 22 050 / 48 000 Hz |
| Channels | mono | stereo |
| Peak level | −1 dBFS, no clipping | |

Why CAF/PCM specifically: `UNNotificationSound` only plays **linear PCM, MA4,
µ-law or a-law** inside `aiff`, `wav` or `caf`. An `m4a` or `mp3` file works for
alarms and for in-app previews, but iOS will fall back to the default tone when
the same file is used for a *notification*. If you want one file to serve both
paths, make it CAF/PCM.

Convert with the system tool:

```sh
afconvert -f caff -d LEI16@44100 -c 1 source.m4a mekke-ezani.caf
```

### Length

* **Alarm path (AlarmKit):** plays the recording in full — this is the whole
  point of the iOS 26 alarm route, and the reason the app prefers it.
* **Notification path:** iOS stops the sound at **30 seconds**, no matter how
  long the file is. Nothing can be done about this from inside the app; it is a
  platform limit, and the app says so in plain language when you import a longer
  file rather than letting you find out at Fajr.

A practical compromise: ship a full-length recording for alarms, and a second
≤30 s edit named `*-short.caf` for people who keep the notification path.

## Where files live at runtime

| Location | Holds | Why |
| --- | --- | --- |
| App bundle (`Resources/Audio`) | files you ship | read-only, discovered at launch |
| App Group container, `AdhanSounds/` | generated tones + user imports | survives updates, readable by the widgets extension |
| `~/Library/Sounds/` | mirror of the above | the **only** place besides the bundle that `UNNotificationSound(named:)` searches |

`AdhanFileStore` keeps the mirror in sync; nothing else needs to know about it.

## Licensing checklist for the owner

Before shipping any recording, make sure you hold:

- the muezzin's performance rights,
- the recording (master) rights,
- distribution rights for every App Store territory you ship in.

"Found on YouTube" is not a licence. If in doubt, ship no recording — the app is
fully usable with the generated tones and user imports, which is exactly why it
was built that way.
