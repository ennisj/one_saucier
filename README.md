# One Saucier

**One Saucier** is a standalone, on-device downloader for the AtGames Legends
Ultimate (ALU). It runs directly on the cabinet and downloads / installs
OnesaUCE content from Archive.org onto the drive it's running from — no PC
required after setup.

## Features

- Browse the full OnesaUCE catalog (base build, 75+ game packs, videos, themes)
  right on the cabinet
- Parallel downloads with pause / resume / cancel, automatic retry, and
  resumable partials that survive reboots
- Crash-safe staged installs — an interrupted install never leaves a component
  half-updated
- Version-aware: shows what's installed, what has updates, and skips
  already-current components
- Archive.org sign-in with the on-screen keyboard (credentials persist)
- Quit straight into the OnesaUCE frontend
- Automatic self-update from this repository's releases

## Installation

1. Download `one_saucier_v<version>.zip` from the
   [latest release](https://github.com/ennisj/one_saucier/releases/latest).
2. Extract it to the **root of your OnesaUCE USB drive** so that
   `one_saucier.uce` and the `one_saucier/` folder sit side by side at the
   drive root.
3. Insert the drive, boot the ALU, and select **One Saucier** from the games
   menu (BYOG section).

An Archive.org account is required for downloads — create one at
[archive.org](https://archive.org/account/signup) and sign in from the app's
Settings screen.

## Updating

The app checks this repository for a newer release at startup and offers the
update in-app (Menu → *Install app update*). Applying it takes a few seconds;
the new version runs on the next launch. Your sign-in, settings, and download
state are always preserved.

## Controls

| Control | Action |
| --- | --- |
| Stick / D-pad | Navigate |
| A | Select / confirm |
| Z / C | Previous / next tab |
| Menu | Contextual options (install, pause, resume, cancel, quit…) |
| Rewind / B | Close dialog; quit (from Home) |

## Screenshots

<!-- Screenshots live in docs/ and are embedded here. -->

*(coming soon)*
