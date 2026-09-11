# Android port — feasibility audit

> Written 2026-09-11 against the newest One Saucier source branch,
> `onesauce_dl` **`bugfix/0.4.2`** (commit `ea2a979`, 2026-09-08,
> `ONESAUCE_DL_VERSION = "v0.4.2"`), which is the tip beyond `main` and the
> working state toward the next release. There is no branch or tag named
> `v0.5.0` in `onesauce_dl` (branches: `main`, `desktop-port`,
> `bugfix/0.2.1`, `bugfix/0.4.2`, `bugfix/virtual-pad-double-input`,
> `release/0.2.1`; tags run to `v0.4.1` here and `v0.4.2` is in release
> prep), so this audit treats `bugfix/0.4.2` as "the v0.5.0 working branch".
> Re-run the verification script (below) if a real `v0.5.0` branch diverges.
>
> This is the Android counterpart of `onesauce_dl/docs/macos-port.md`: the
> same shape (verdict → measured deltas → build plan → what is still
> unverified), so it can be the handoff for whoever starts the port. It lives
> in this repo only because the audit session had no push access to
> `onesauce_dl`; move it to `onesauce_dl/docs/android-port.md` beside the
> macOS one, and `docs/android/verify_android_sources.sh` to
> `onesauce_dl/scripts/`.

## Verdict

**Feasible at the code level — more so than macOS was at its audit.** The
whole desktop build (the exact translation-unit list `build_mac.sh` links,
minus the Objective-C++ picker) was cross-compiled unmodified with the
Android NDK and linked into the `libmain.so` an SDL2 Android app loads:

| Check (NDK r27c, clang 18, `-DONESAUCE_HOST -DONESAUCE_DESKTOP`) | Result |
|---|---|
| App + RetroFE + ImGui TUs, arm64-v8a, API 24 | **64 / 64 compile, 0 errors** (33 warnings: 32 `-Wunused-function`, 1 `-Wnull-character` — the host build's usual set) |
| Pure decision layer (catalog, version_state, download_plan, prefs, unzip, untargz, md5, browse, component_detail, retention, uninstall, onesauce_settings + the purity-gate RetroFE modules), armeabi-v7a, API 24 | **29 / 29 compile** |
| Same, armeabi-v7a, API **21** | miniz fails: bionic has no `ftello`/`fseeko` before API 24 → **minSdk = 24 (Android 7.0)** |
| 64-bit file offsets at API 24 with `_FILE_OFFSET_BITS=64` | `sizeof(off_t) == 8`, `st_size` 8 bytes, `ftello`/`fseeko` present (static-asserted) — the >4 GB / ZIP64 install path carries over |
| Link `libmain.so` against an NDK-built SDL2 2.30.11 + libcurl 8.11.1 with `-Wl,--no-undefined` | **exactly one undefined symbol: `mac_pick_folder`** (the NSOpenPanel picker in `mac_pick_folder.mm`). Stubbed → links. 8.2 MB, 4.9 MB stripped; `SDL_main` exported; NEEDED = libSDL2, liblog, libandroid, libGLESv2/v1_CM, libz, libc++_shared |

So the porting work is not "make it compile". It is (a) ~5 small,
well-localized behavior deltas in `main.cpp`'s `ONESAUCE_DESKTOP && !_WIN32`
branches, which today assume macOS, (b) the Android packaging/lifecycle
layer that every SDL app needs, and (c) **one product decision that decides
whether the port is worth doing at all** — see the next section first.

## The product question: what would an Android One Saucier do?

One Saucier has two roles today. The cabinet build writes the drive it runs
from. The desktop build (Windows/macOS) either installs into a local folder /
the OnesaUCE drive, or downloads packs and pushes them to the cabinet over
Cabinet Link. Only the second role survives on Android:

- **Writing the OnesaUCE drive from a phone: not viable on stock Android.**
  OnesaUCE requires an NTFS drive (v0.4.2's own drive-format guard). AOSP has
  no NTFS support; `vold` mounts FAT32/exFAT only (a few OEMs read NTFS, none
  reliably write it). Even a mountable volume sits behind scoped storage:
  POSIX writes to `/storage/XXXX-XXXX` need the `MANAGE_EXTERNAL_STORAGE`
  permission (Play-policy restricted) and removable volumes otherwise go
  through SAF `content://` URIs, which the extractor/staging code (POSIX
  paths, same-volume `rename` sweep, `fsync`, `statvfs`) cannot use. Drop
  the "local install folder / OnesaUCE drive" rows on Android.
- **The Cabinet Link role maps cleanly.** Discovery is a UDP probe to `:47654`
  with unicast replies (no multicast lock needed), control is HTTP/JSON via
  libcurl to `:47655`, and the phone runs the zip file server on `:47656`
  that the cabinet pulls from — plain BSD sockets, all supported by bionic
  (`MSG_NOSIGNAL` exists; `SIGPIPE` ignore compiles). Needs only the
  `INTERNET` permission. Catalog browsing, downloads to the app's own
  storage, per-component and per-item cabinet transfer, cabinet status, and
  cabinet-side uninstall all work off code that already compiled.
- **Android TV / Fire TV is the natural first target, not the phone.** The
  UI is controller-first (D-pad/stick navigation, A/B/Z/C, on-screen
  keyboard) on a fixed 1920×1080 canvas — exactly a 10-foot TV UI. SDL's
  GameController layer works on Android (Bluetooth pads, TV remotes report
  as D-pad). Phones work too: SDL synthesizes mouse events from touch by
  default, so the existing pointer hit-boxes make taps into clicks, and the
  `Vertical` 1080×1920 canvas is a ready-made portrait layout — but a
  1080p-designed table at phone size is small, and hover highlights don't
  exist under touch.
- **Browse / Themes tabs need an installed OnesaUCE tree.** On a drive-less
  Android install they show the same "installation not found" state as a
  drive-less desktop. They compile and could run against a local copy, but
  there is no real use; hide them or keep them dormant.
- **Companion (PySide6/Python) is not the codebase for this.** Qt for
  Python on Android is experimental and the app is Windows/macOS-shaped;
  One Saucier's C++/SDL2 core is the right vehicle, and this audit shows
  it is already most of the way there.

If a "Cabinet Link remote" (and/or an Android TV build) is a product you want,
proceed. If the only value would be writing the drive, stop here.

## Measured code deltas (exact locations, `app/main.cpp` on `bugfix/0.4.2`)

Every item below is in a `#if defined(ONESAUCE_DESKTOP) && !defined(_WIN32)`
(or `#else` of `_WIN32`) branch that was written for macOS. All compile on
bionic; the problem is what they *do* at runtime.

1. **Data dir / asset seeding (would fail at first launch).**
   `desktop_exe_dir()` (~line 153) uses `SDL_GetBasePath()`, which returns
   NULL on Android → `"."` → cwd `/` → every cfg/log/workdir write fails.
   `mac_data_dir()` (~line 202) then builds `$HOME/Library/Application
   Support/one_saucier` (`HOME` is unset on Android). Fix: an
   `android_data_dir()` returning `SDL_AndroidGetInternalStoragePath()`
   (cfg/logs/`.one_saucier/`) with downloads under
   `SDL_AndroidGetExternalStoragePath()` (the app-specific external dir —
   no storage permission, survives the multi-GB packs), and the existing
   `mac_seed_data_dir()` pattern (~line 182) copying `Roboto-Regular.ttf`,
   `gamecontrollerdb.txt`, `WHATSNEW.txt`, `CHANGELOG.txt` out of the APK
   via `SDL_RWFromFile` (which reads APK assets on Android) instead of
   `fopen`. ~40 lines; `desktop_data_dir()` (~line 220) dispatches.
2. **Folder picker (the one link error).** `desktop_pick_folder()` (~line
   690) calls `mac_pick_folder()` from `mac_pick_folder.mm`. Android's
   picker is an `ACTION_OPEN_DOCUMENT_TREE` intent returning a `content://`
   URI, useless to POSIX code. Don't port it: on Android the FOLDERS card
   keeps only the Downloads folder, fixed to the app's external files dir,
   and the picker rows (`SET_INSTALL_DIR`, `SET_DOWNLOAD_DIR`, the drive
   radio + letter dropdown, ~lines 5630-5697 and 6420-6456) are hidden. A
   one-line stub satisfies the linker today.
3. **Self-update apply + relaunch (must be replaced, not ported).** The
   desktop install step (~lines 1157-1212) copies the staged payload over
   `desktop_exe_dir()` or swaps the `.app`, then `relaunch_self()` (~line
   13691) does `fork`/`execl`. An APK is read-only and a process cannot
   re-exec itself. Keep the release check (GitHub API, already
   platform-aware since v0.4.2) and add an `_android.apk` row to the
   per-platform asset table in `download_plan.h` (~lines 125-143, plus its
   unit test); "Update" then hands the downloaded APK to the package
   installer via an intent (`REQUEST_INSTALL_PACKAGES`, "install unknown
   apps" prompt once) — or simply opens the releases page. Play Store
   distribution would remove this code path entirely.
4. **RetroFE tessellation budget mis-detects Android as the cabinet.**
   `RetroSDL::transformBudgetDevice()` (`app/retrofe/SDL.cpp` ~line 369)
   turns the Mali-400 subdivision ceiling on for `__arm__ || __ARM_ARCH`.
   The NDK's aarch64 clang defines `__ARM_ARCH 8`, so every Android build
   (32- and 64-bit) silently gets the cabinet's budget. Add
   `&& !defined(__ANDROID__)` (or key it on `!ONESAUCE_DESKTOP`). Only
   matters if the theme preview is ever shown on Android, but it is a
   one-token fix and a unit test already pins the env override.
5. **Filesystem-type probe.** `fs_name_for_path()` (~line 413) takes the
   Linux `statfs` magic branch on bionic — harmless, but its verdict only
   matters for the drive-install role that Android drops.

Things that looked like deltas and are **not**:

- `MSG_NOSIGNAL` / `SIGPIPE`: bionic is Linux — native flag, and the
  startup `signal(SIGPIPE, SIG_IGN)` (~line 13736) is fine.
- The `pthread_create` interposer (`dlsym(RTLD_NEXT, …)`, ~line 752) is
  `#ifndef ONESAUCE_HOST` — device-only, not compiled.
- `dns_override.cpp` is device-only and not in the desktop list.
- `int main()` becomes `SDL_main` through `SDL_main.h`'s macro — verified
  exported from `libmain.so`. `--selftest` / `--apply-update` argv paths
  are simply unreachable.
- Windows drive-letter code (`GetLogicalDrives`, `win_compat.h`) is behind
  `_WIN32`.
- miniz takes its plain `fopen/ftello/fseeko` path (bionic does not define
  `__USE_LARGEFILE64`) — correct at API 24 with `_FILE_OFFSET_BITS=64`, as
  measured above.
- `SDL_RenderGeometry` (theme preview) needs SDL ≥ 2.0.18 — the Android
  build is 2.30.

## Android-only work (no desktop equivalent)

These are the real cost of the port; none is unusual for an SDL2 app.

- **Foreground service + wake/Wi-Fi locks.** Multi-GB downloads and the
  cabinet *pulling* a 5 GB pack from the phone's `:47656` server must
  outlive the screen turning off. SDL's `SDLActivity` pauses the render
  loop on background (`SDL_HINT_ANDROID_BLOCK_ON_PAUSE`) but worker threads
  keep running while the process lives; only a Java foreground service with
  a persistent notification keeps the process alive under Doze. The app has
  no `SDL_APP_WILLENTERBACKGROUND` handling today (only `SDL_QUIT`); the
  job model's pause/resume already survives restarts, so a killed process
  is recoverable but not what users expect. Wi-Fi only: the cabinet is on
  the LAN.
- **TLS for libcurl.** The link-verification curl was HTTP-only. Ship curl
  with a TLS backend (OpenSSL/BoringSSL or mbedTLS built with the NDK) and
  either the existing `curl-ca-bundle.crt` (the code already honours
  `CACERT` → `CURLOPT_CAINFO`) or `CURLOPT_CAPATH` at
  `/system/etc/security/cacerts`. Archive.org and GitHub are HTTPS; the
  cabinet link is plain HTTP on the LAN, which raw curl does not restrict
  (Android's cleartext policy applies to the Java network stack, not native
  sockets).
- **Video (Game / Collection Details).** No prebuilt LGPL ffmpeg for
  Android from BtbN; reuse the `setup_ffmpeg_mac.sh` source-build recipe
  with the NDK toolchain, or ffmpeg-kit's LGPL package. Absent, the player
  compiles to stubs (thumbnails only) — that is how this audit linked.
  MediaCodec hardware decode is the same shape as the cabinet's rkmpp path
  (NV12 fast path already exists).
- **Input polish.** Map the Back button (`SDL_SCANCODE_AC_BACK`, or
  `SDL_AndroidBackButton`) to the Esc action; the soft keyboard already
  appears because the loop calls `SDL_StartTextInput()` when a text field
  has focus (desktop in-place typing uses `SDL_TEXTINPUT`, which Android
  delivers). Decide phone vs TV: TV needs a leanback launcher intent and a
  banner; phone needs the vertical canvas by default and larger hit
  targets.
- **Packaging.** SDL2 ships `android-project/` (Gradle + `SDLActivity`
  Java); drop `libmain.so`, `libSDL2.so`, `libc++_shared.so` (and ffmpeg
  if built) into `jniLibs/arm64-v8a`, assets into `assets/`. Manifest:
  `INTERNET`, `FOREGROUND_SERVICE`, `REQUEST_INSTALL_PACKAGES` (only for
  in-app update), `android:largeHeap` not needed. Sign with a keystore
  kept out of the repo; sideload via GitHub releases matches the current
  distribution model.

## Build plan (mirrors the per-platform scripts)

- `scripts/setup_android.sh` — stage under `~/alu/android/`: NDK (r27c;
  664 MB), SDL2 2.30.x built with the NDK CMake toolchain
  (`-DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-24`, ~3 min),
  curl + TLS, optional ffmpeg. Reuse `setup_imgui.sh` unchanged.
- `scripts/build_android.sh` — sibling of `build_mac.sh`: same
  `RETROFE_SRC` list, same `LF` large-file macros, `-fPIC`,
  `-DONESAUCE_HOST -DONESAUCE_DESKTOP` (plus an `ONESAUCE_ANDROID` toggle
  for the four runtime deltas), links `libmain.so` with
  `-Wl,--no-undefined -lSDL2 -lcurl -llog -landroid -lGLESv2 -lGLESv1_CM
  -lz`, then Gradle-assembles the SDL template into an APK. Add it to
  `check_source_lists.sh`'s parity gate.
- CI: `build-android.yml` on `ubuntu-latest` — GitHub's Ubuntu image
  preinstalls the Android SDK and NDK, so this is a cheap Linux runner
  like `build-windows`, not a 10× macOS runner. Same `ci-builds` fallback.
- Release asset: `one_saucier_v<X.Y.Z>_android.apk`, exact-name matched
  like the other three (the v0.4.2 rule).
- **`docs/android/verify_android_sources.sh`** is the audit's compile+link
  gate, written to run from the `onesauce_dl` root and to read the TU list
  out of `build_mac.sh`. It reproduced the table above end to end. Run it
  before touching code, then keep it green.

## Rough effort

- **Spike (a couple of days):** `build_android.sh` + the SDL Gradle
  template + delta 1 (data dir/asset seeding) + the picker stub → an APK
  that boots to Home, signs in, and browses the catalog on an Android TV
  box or phone. This is the go/no-go checkpoint on real hardware.
- **Usable Cabinet Link remote (one to two weeks):** foreground service and
  locks, TLS curl + CA bundle, hide the install/drive rows, Back button and
  touch/TV input polish, `_android.apk` release row + update-by-intent,
  `build-android.yml`.
- **Later:** ffmpeg video, leanback banner, Play Store if ever wanted.

## What this audit did NOT verify

- Nothing ran on a device or emulator: no rendering, input, audio, or
  network behavior was observed. The storage and permission conclusions are
  from platform documentation, not measurement.
- No APK was assembled (the NDK toolchain was downloaded and used; the
  Android SDK/Gradle template was not exercised).
- curl was built HTTP-only; TLS and CA handling on Android are unproven.
- ffmpeg was absent (player stubs), so `ONESAUCE_VIDEO` on Android is
  unbuilt.
- armeabi-v7a was verified for the pure layer only; the full app was
  compiled for arm64-v8a. (32-bit-only Android devices are rare in 2026;
  arm64-only is a defensible first ship.)

## Reproducing the measurements

```bash
# one-time staging (any Linux box; ~10 min, mostly the NDK download)
curl -LO https://dl.google.com/android/repository/android-ndk-r27c-linux.zip && unzip -q android-ndk-r27c-linux.zip -d ~/alu/android && mv ~/alu/android/android-ndk-r27c ~/alu/android/ndk
curl -LO https://www.libsdl.org/release/SDL2-2.30.11.tar.gz && tar xzf SDL2-2.30.11.tar.gz
cmake -S SDL2-2.30.11 -B sdl2-android -G Ninja -DCMAKE_TOOLCHAIN_FILE=~/alu/android/ndk/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-24 -DCMAKE_BUILD_TYPE=Release -DSDL_TEST=OFF \
      -DCMAKE_INSTALL_PREFIX=~/alu/android/sdl2 && ninja -C sdl2-android install
curl -LO https://curl.se/download/curl-8.11.1.tar.xz && tar xJf curl-8.11.1.tar.xz
cmake -S curl-8.11.1 -B curl-android -G Ninja -DCMAKE_TOOLCHAIN_FILE=~/alu/android/ndk/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-24 -DBUILD_SHARED_LIBS=OFF -DBUILD_CURL_EXE=OFF \
      -DCURL_ENABLE_SSL=OFF -DHTTP_ONLY=ON -DCMAKE_INSTALL_PREFIX=~/alu/android/curl && ninja -C curl-android install
bash scripts/setup_imgui.sh

# the gate (from the onesauce_dl root)
bash /path/to/one_saucier/docs/android/verify_android_sources.sh          # arm64, API 24 -> RESULT: PASS
ANDROID_ARCH=armv7a bash /path/to/one_saucier/docs/android/verify_android_sources.sh
```
