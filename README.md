# One Saucier

<p align="center">
  <img src="docs/one_saucier_logo.png" alt="One Saucier" width="340">
</p>

**One Saucier** is a downloader and library manager for **OnesaUCE** content
from Archive.org. It runs directly on the AtGames Legends Ultimate (ALU)
cabinet and on the Legends Pinball (full-size and Micro), installing content
onto the drive it's running from, no PC required. It also ships as
**Windows and macOS apps** that can manage a local library and pair with your
cabinets over your home network.

**Current release: v0.6.0.** See the
[releases page](https://github.com/ennisj/one_saucier/releases) for what's
new in each version.

## Features

**Install and update**

- **Browse the full OnesaUCE catalog**: base build, 75+ game packs, videos,
  and themes, with live install status for every component
- **Install single games and videos**: open a System Pack or video
  collection to see its individual games, their sizes, and their install
  state, then install or remove them one at a time; each collection's shared
  files download once as its Component Base, so every game after that costs
  only its own few megabytes
- **Parallel downloads**: up to 8 components at once, each with pause,
  resume, and cancel; interrupted downloads survive reboots and resume where
  they stopped. The **JOBS** card shows every download, install, and transfer
  with its progress
- **Crash-safe staged installs**: components are extracted to a staging area
  and moved into place only when complete, so a power cut can never leave a
  component half-updated
- **Version-aware**: sees what's installed, flags updates, skips components
  that are already current, and remembers downloads that are still waiting to
  install ("Ready to Install")
- **Uninstall** game packs, videos, and themes from the Catalog; files shared
  with other components are kept automatically. Installing or updating never
  replaces a save file you already have
- **Sort and filter the Catalog** by any column and by status; it keeps
  working offline, falling back to the last saved copy when Archive.org can't
  be reached

**Manage your library** (new in v0.6.0)

- **Manage** searches everything on your drive (games, systems,
  collections, themes, videos, customizations, and Custom Packs), and every
  row opens a dialog of its own
- **Per-game and per-system settings**: the launcher, RetroArch settings
  (aspect ratio, shader, bezel, run-ahead...), every core option, and the
  controls, plus the settings of DraStic, Flycast, and PPSSPP
- **Customizations**: your settings changes, playlists, themes, menus, and
  collections are saved as named customizations. Switch one off to put
  everything back, or on to apply it again; they survive updates to the
  components they change
- **Metadata**: fix a game's title, year, manufacturer, genre, and the rest
  of what the frontend shows
- **Your own collections, menus, and playlists**, with artwork and
  descriptions
- **Add your own games** to any system on the drive: pick the file on a PC,
  or copy it into the drive's `one_saucier/inbox` folder and add it on the
  cabinet. One Saucier checks it first and says plainly when a game cannot be
  added
- **Saves**: see every game's saves and save states, back them up, restore
  them, and carry them between a PC and a cabinet

**Share** (new in v0.6.0)

- **Custom Packs**: publish your customizations, added games, and save
  backups on Archive.org for other OnesaUCE owners. Find packs by name,
  author, or what they contain; subscribe, and updates arrive when the author
  changes the pack. Publishing always shows exactly what will be uploaded
  first

**Themes**

- **Live theme preview**: the BROWSE tab shows every installed theme
  full-screen, drawn by the same engine the cabinet uses (animations, music,
  and game videos included). Browse your games inside it, with their marquees,
  logos, story text, artwork, and videos, and apply the theme right from it
- **Theme Editor** (since v0.5.0): create OnesaUCE themes on the cabinet or
  on your PC, on a live canvas, with templates per category or system and a
  second screen for the Legends Pinball. Example projects for every OnesaUCE
  theme show how they were made. Find your projects under Manage ▸ Themes

**On the cabinet and pinball**

- **Two layouts**: the standard horizontal layout, plus a **Vertical** one
  for rotated monitors and pinball cabinets (Settings ▸ Theme)
- **Edit OnesaUCE's own options** from Settings: pinball rotation fix,
  default theme, video options, attract-mode timings, and more
- **Archive.org sign-in on screen**, with a full on-screen keyboard,
  remembered once entered
- **Quit straight into the OnesaUCE frontend**, with no round-trip through
  the ALU menu
- **Self-updating**: One Saucier appears in its own catalog as the first
  row and updates itself from this repository's releases
- **What's New**: the release notes for every version, right on the cabinet

**On your PC or Mac**

- The same app, windowed and resizable, driven by keyboard, mouse, or gamepad
- Browse the catalog, download components, and keep copies in a local library
  folder for later
- **Pair with your cabinets** (Settings ▸ Cabinet Link) to see each
  component's install status on the cabinet and **send content straight to it
  over your home network**, down to a single game or video at a time. A PC can
  pair with several cabinets and pinballs and switch between them
- Folder and file names in any language work on Windows 10 (version 1903) or
  later

## Installation

Every release ships one download per platform. Grab them from the
[latest release](https://github.com/ennisj/one_saucier/releases/latest).
An Archive.org account is required for downloads. Create one at
[archive.org](https://archive.org/account/signup) and sign in from the app.

### Cabinet and pinball

1. Download `one_saucier_v<version>_cabinet.zip`.
2. Extract it to the **root of your OnesaUCE USB drive** so that
   `one_saucier.uce` and the `one_saucier/` folder sit side by side at the
   drive root (replacing any older copies; your sign-in and settings are
   kept).
3. Insert the drive, boot the machine, and select **One Saucier** from the
   games menu (BYOG section).

### Windows

1. Download `one_saucier_v<version>_windows.zip`.
2. Unzip it anywhere and run `one_saucier.exe`. Everything it needs is in
   the folder, and its settings, logs, and downloads stay next to the exe.
3. Point it at the folder that holds (or will hold) your OnesaUCE files, or
   skip straight to pairing with the cabinet.

### macOS

The app is a universal binary. It runs natively on both Apple Silicon and
Intel Macs, on **macOS 11 (Big Sur) or later**.

1. Download `one_saucier_v<version>_macos.tar.gz` and unpack it.
2. Move `one_saucier.app` wherever you like (**Applications** works) and
   open it (see the first-launch note below).
3. The app keeps its settings, logs, and downloads in
   `~/Library/Application Support/one_saucier`.

Because the app isn't signed with a paid Apple certificate yet, macOS shows a
security warning the **first time** you open it. This is expected, and you
only need to get past it once.

**On macOS 15 Sequoia and newer:**

1. Double-click the app. When macOS says it can't be opened because Apple
   cannot verify it, click **Done** (do *not* click "Move to Trash").
2. Open the **Apple menu ▸ System Settings ▸ Privacy & Security**.
3. Scroll to the **Security** section, find the line saying *"one_saucier"
   was blocked*, and click **Open Anyway**.
4. Confirm with Touch ID or your password, then click **Open Anyway** once
   more. The app launches and won't ask again.

**On macOS 11 Big Sur through 14 Sonoma**, the quicker method works instead:
right-click (or Control-click) the app and choose **Open**, then **Open**
again.

**If you see "one_saucier is damaged and can't be opened"**, that is the
download-quarantine flag, not actual damage. Open the **Terminal** app, paste
the line below (adjusting the path if the app isn't in Applications), press
Return, then open the app normally:

```bash
xattr -dr com.apple.quarantine /Applications/one_saucier.app
```

## Signing in

Open **Settings** and enter your Archive.org email and password, with the
on-screen keyboard on the cabinet or by typing on the desktop versions.
**Validate** checks them against Archive.org and stores them with the app's
settings, so you stay signed in across launches. The Catalog's **ACCOUNT**
card shows who is signed in.

Settings also holds the download options: auto-install after download, resume
partials on start, how many components download in parallel, and optional
backups of files an update overwrites.

## The tabs

| Tab | What it's for |
| --- | --- |
| **Catalog** | Everything you can download, with the ACCOUNT, DRIVES, INSTALLED, and JOBS cards beside it |
| **Browse** | Your installed games, inside the live theme preview |
| **Manage** | Search and change what's on your drive: games, systems, collections, themes, videos, customizations, Custom Packs |
| **Settings** | Sign-in, downloads, folders, Cabinet Link, OnesaUCE's options, and the Log |

## Browsing and installing

The **Catalog** lists every component grouped by category, with its size, the
available version, your installed version, and a colour-coded status. Sort
it by any column or filter it by status. One Saucier itself is the first row,
and it updates like everything else. On a PC paired with cabinets, each
machine has its own column: green up to date, gold an update, grey not
installed.

Select a component with **A** and confirm to download and install it. Pick
several: they queue up and download in parallel while installs run one at a
time in the background. The status column tracks every state:

| Status | Meaning |
| --- | --- |
| **Up to date** | Installed and current |
| **Update Available** | Installed, but a newer version exists |
| **Not installed** | Available to download |
| **Downloading / Installing** | In flight right now |
| **Queued for Download** | Waiting for a parallel-download slot |
| **Paused** | Stopped by you; resumes where it left off |
| **Ready to Install** | Downloaded but not yet installed (kept across restarts) |
| **Pending Restart** | A One Saucier update is installed; restarts into the new version |

The **Menu** button opens contextual options wherever you are: install,
uninstall, or force re-download the selected component, pause / resume /
cancel its download, hide up-to-date rows, refresh the catalog, and quit.

## Pairing a PC or Mac with the cabinet

With One Saucier running on both the cabinet and your computer (on the same
home network), open **Settings ▸ Cabinet Link** and pair them with the short
PIN. Once linked, the desktop app shows each component's install status *on
the cabinet*, and anything in your local library can be sent straight to it:
downloads can happen at your desk and installs on the couch. A paired PC can
also send an added game or a save backup to the cabinet, and fetch a game's
saves from it.

## Updating One Saucier

The cabinet app checks this repository for a newer release at startup. When
one exists, the **One Saucier** catalog row shows *Update Available*. Install
it like any component. After it applies, the row reads **Pending Restart**:
choose *Menu → Quit → Quit and restart* and the new version boots
immediately. Your sign-in, settings, customizations, and download state are
always preserved. The Windows and macOS apps update themselves the same way.

## Controls

**On the cabinet**

| Control | Action |
| --- | --- |
| Stick left / right | Switch tabs |
| Stick up / down | Move through lists, line by line |
| A | Select / confirm / toggle |
| Z / C | Page up / page down |
| Menu | Contextual options |
| Rewind / B | Close dialog / back |
| Trackball | Point and click: rows, tabs, controls, video scrubbing |

**On the pinball**, the left flipper and nudge buttons page, and the right
pair switches tabs. **On a gamepad**, L1 / L2 page and R1 / R2 switch tabs.
The hint strip at the bottom of the screen always shows the buttons for the
controller you're using.

**On Windows and macOS**, a gamepad works exactly like the cabinet's
controls, or use the keyboard:

| Key | Action |
| --- | --- |
| Arrow keys | Navigate (stick) |
| Enter / Space | Select / confirm (A) |
| Backspace | Back / close dialog |
| M | Contextual menu |
| Page Up / Page Down | Page up / page down |
| `[` / `]` | Previous / next tab |
| Esc | Close dialog / quit |
| F10 | Switch between the horizontal and vertical layout (this session) |
| F11 or Alt+Enter | Toggle fullscreen |

Text fields take normal typing.

## Good to know

- On the cabinet, downloads, staged installs, backups, logs, and settings all
  live inside `one_saucier/.one_saucier/` on the drive. Nothing is written
  at the drive root. On Windows the same `.one_saucier/` folder sits next to
  the exe; on macOS it's in `~/Library/Application Support/one_saucier`.
- If something goes wrong, the `.one_saucier/activity.log` in that folder
  holds a timestamped record of every session. Include it when reporting an
  issue.
- Very large packs are multi-hour downloads. You can pause them, quit, or
  power off; progress is kept and resumes on the next attempt.

## Licenses

One Saucier is closed-source, but it builds on open-source components: Dear
ImGui, miniz, the LZMA SDK, FFmpeg (LGPL, dynamically linked), SDL2, the
Roboto font, and more.
[THIRD_PARTY_LICENSES.txt](THIRD_PARTY_LICENSES.txt) lists every component
with its license and source, and the [licenses/](licenses/) folder carries the
full license texts. The same notices ship inside every release: in the cart's
`.uce` image, next to the Windows exe, and inside the macOS app
(`Contents/Resources/`).
