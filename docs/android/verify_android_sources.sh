#!/usr/bin/env bash
# Android COMPILE + LINK verification for One Saucier (the onesauce_dl sources).
#
# Companion to docs/android-port-feasibility.md. Run it from the ROOT of an
# onesauce_dl checkout (it reads scripts/build_mac.sh for the desktop source
# list, so the list can never drift from the real desktop builds):
#
#     bash /path/to/verify_android_sources.sh
#
# It is NOT an APK build. It answers one question: does every translation unit
# of the desktop build (-DONESAUCE_HOST -DONESAUCE_DESKTOP, the same defines as
# build_win.sh / build_mac.sh) compile with the Android NDK's clang for
# arm64-v8a at API 24, and does the result link into the libmain.so an SDL2
# Android app loads, with NO undefined symbols? On the 2026-09 audit the answer
# was yes: 64/64 TUs, one missing symbol (mac_pick_folder, the NSOpenPanel
# picker) which this script stubs -- see the report for why that is expected.
#
# Inputs (env vars, all with a ~/alu/android default like the other setup_*
# scripts' ~/alu layout):
#   ANDROID_NDK   NDK root (r27c used for the audit; any r25+ should do)
#   SDL2_ANDROID  SDL2 install prefix built with the NDK CMake toolchain
#                 (include/SDL2 + lib/libSDL2.so). Headers alone are enough for
#                 the compile pass; the .so enables the link pass.
#   CURL_ANDROID  curl install prefix (include/curl + lib/libcurl.a). Headers
#                 alone are enough for the compile pass.
#   IMGUI         Dear ImGui checkout (default ~/alu/imgui, as setup_imgui.sh)
#   ANDROID_API   API level (default 24: the floor -- bionic has no 64-bit
#                 ftello/fseeko before it, and miniz's >4 GB path needs them)
#   ANDROID_ARCH  aarch64 (default) or armv7a
set -o pipefail
ROOT="$(pwd)"
[ -f "$ROOT/app/main.cpp" ] && [ -f "$ROOT/scripts/build_mac.sh" ] || {
    echo "ERROR: run from the onesauce_dl repo root (app/main.cpp + scripts/build_mac.sh)"; exit 1; }
NDK="${ANDROID_NDK:-$HOME/alu/android/ndk}"
SDL2P="${SDL2_ANDROID:-$HOME/alu/android/sdl2}"
CURLP="${CURL_ANDROID:-$HOME/alu/android/curl}"
IMGUI="${IMGUI:-$HOME/alu/imgui}"
API="${ANDROID_API:-24}"
case "${ANDROID_ARCH:-aarch64}" in
    aarch64) T="aarch64-linux-android$API" ;;
    armv7a)  T="armv7a-linux-androideabi$API" ;;
    *) echo "ERROR: ANDROID_ARCH must be aarch64 or armv7a"; exit 1 ;;
esac
TC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
[ -x "$TC/$T-clang++" ] || { echo "ERROR: $TC/$T-clang++ missing (set ANDROID_NDK)"; exit 1; }
[ -f "$SDL2P/include/SDL2/SDL.h" ] || { echo "ERROR: SDL2 headers missing at $SDL2P/include/SDL2 (set SDL2_ANDROID)"; exit 1; }
[ -f "$CURLP/include/curl/curl.h" ] || { echo "ERROR: curl headers missing at $CURLP/include/curl (set CURL_ANDROID)"; exit 1; }
[ -f "$IMGUI/imgui.cpp" ] || { echo "ERROR: ImGui missing at $IMGUI (run scripts/setup_imgui.sh)"; exit 1; }

OUT="$ROOT/build/android-verify-$T"; rm -rf "$OUT"; mkdir -p "$OUT"
# Same large-file macros as every other build (miniz's >4 GB / ZIP64 path).
LF="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64"
# Same warning set as build_win.sh / build_host.sh. -fPIC because an Android
# app's native code is a shared library (the first link attempt without it
# failed on R_AARCH64_ADR_PREL_PG_HI21 relocations).
WARN="-Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers"
INC="-I$SDL2P/include -I$SDL2P/include/SDL2 -I$CURLP/include -I$IMGUI -I$IMGUI/backends -I$ROOT/app -I$ROOT/app/retrofe"

echo ">> target $T  (NDK: $NDK)"
echo ">> compiling miniz.o (C, large-file, PIC)"
"$TC/$T-clang" -O2 -fPIC $LF -c "$ROOT/app/miniz.c" -o "$OUT/miniz.o" || { echo "FAIL miniz.c"; exit 1; }

# The desktop TU list, read from build_mac.sh itself (RETROFE_SRC array +
# the explicit app/*.cpp on its link line), minus mac_pick_folder.mm.
RETROFE_SRC=$(sed -n '/^RETROFE_SRC=(/,/^)/p' "$ROOT/scripts/build_mac.sh" | grep -oE 'app/retrofe/[A-Za-z/]+\.cpp')
APP_SRC=$(grep -oE '"\$ROOT/app/[a-z0-9_]+\.cpp"' "$ROOT/scripts/build_mac.sh" | tr -d '"' | sed 's|\$ROOT/||' | sort -u)
fail=0; n=0
compile() {   # $1 = source path relative to ROOT, $2 = extra flags
    local src="$1" obj="$OUT/$(echo "$1" | tr '/' '_' | sed 's/\.cpp$/.o/')"
    if "$TC/$T-clang++" -O2 -fPIC -std=c++17 $WARN $LF -DONESAUCE_HOST -DONESAUCE_DESKTOP $2 $INC \
        -c "$ROOT/$src" -o "$obj" 2>"$obj.err"; then echo "OK   $src"; else echo "FAIL $src"; grep -E "error:" "$obj.err" | head -5; fail=$((fail+1)); fi
    n=$((n+1))
}
echo ">> compiling the desktop source list for Android"
for f in $APP_SRC $RETROFE_SRC; do compile "$f" ""; done
echo ">> compiling Dear ImGui + the sdl2 / sdlrenderer2 backends"
for f in imgui imgui_draw imgui_tables imgui_widgets backends/imgui_impl_sdl2 backends/imgui_impl_sdlrenderer2; do
    obj="$OUT/imgui_$(basename "$f").o"
    if "$TC/$T-clang++" -O2 -fPIC -std=c++17 -I"$SDL2P/include" -I"$SDL2P/include/SDL2" -I"$IMGUI" -I"$IMGUI/backends" \
        -c "$IMGUI/$f.cpp" -o "$obj" 2>"$obj.err"; then echo "OK   imgui/$f"; else echo "FAIL imgui/$f"; fail=$((fail+1)); fi
    n=$((n+1))
done
echo ">> compile: $n TUs, $fail failed, $(cat "$OUT"/*.err | grep -c 'warning:') warnings"
[ "$fail" -eq 0 ] || { echo "RESULT: FAIL (compile)"; exit 1; }

# Link pass -- only when the Android SDL2 .so and libcurl.a are staged.
if [ -f "$SDL2P/lib/libSDL2.so" ] && [ -f "$CURLP/lib/libcurl.a" ]; then
    # The one symbol the desktop sources leave to a platform file:
    # mac_pick_folder (app/mac_pick_folder.mm, NSOpenPanel). Android has no
    # POSIX-path folder picker (SAF returns content:// URIs), so the port
    # replaces the picker rows rather than porting the picker; a stub proves
    # nothing ELSE is missing.
    printf '#include <string>\nstruct SDL_Window;\nstd::string mac_pick_folder(SDL_Window*, const char*) { return std::string(); }\n' > "$OUT/picker_stub.cpp"
    "$TC/$T-clang++" -O2 -fPIC -std=c++17 -c "$OUT/picker_stub.cpp" -o "$OUT/picker_stub.o"
    echo ">> linking libmain.so (-Wl,--no-undefined)"
    if "$TC/$T-clang++" -shared -Wl,--no-undefined -o "$OUT/libmain.so" "$OUT"/*.o \
        -L"$SDL2P/lib" -lSDL2 "$CURLP/lib/libcurl.a" -llog -landroid -lGLESv2 -lGLESv1_CM -lz -ldl 2>"$OUT/link.err"; then
        "$TC/llvm-strip" -o "$OUT/libmain-stripped.so" "$OUT/libmain.so"
        echo "   libmain.so: $(stat -c %s "$OUT/libmain.so") bytes ($(stat -c %s "$OUT/libmain-stripped.so") stripped)"
        "$TC/llvm-nm" -D --defined-only "$OUT/libmain.so" | grep " T SDL_main$" >/dev/null && echo "   SDL_main exported: yes" || { echo "   SDL_main exported: NO"; fail=1; }
    else
        echo "FAIL link"; grep -E "undefined|error" "$OUT/link.err" | head -20; fail=1
    fi
else
    echo ">> link pass skipped (no $SDL2P/lib/libSDL2.so and/or $CURLP/lib/libcurl.a staged)"
fi
[ "$fail" -eq 0 ] && echo "RESULT: PASS" || { echo "RESULT: FAIL"; exit 1; }
