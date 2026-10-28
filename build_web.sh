#!/usr/bin/env bash
# Web build: Odin compiles the game to a wasm object, emscripten links it with
# raylib's web library and wraps it in web/index_template.html.
# Needs `odin` and `emcc` (emsdk) in PATH. Output: build/web/
set -euo pipefail

OUT_DIR="build/web"
mkdir -p "$OUT_DIR"

# RAYLIB_WASM_LIB=env.o: raylib is not linked by Odin here, emcc feeds it below
odin build . \
	-target:js_wasm32 \
	-build-mode:obj \
	-no-entry-point \
	-define:RAYLIB_WASM_LIB=env.o \
	-vet \
	-o:speed \
	-out:"$OUT_DIR/game.wasm.o"

ODIN_PATH="$(odin root)"
cp "$ODIN_PATH/core/sys/wasm/js/odin.js" "$OUT_DIR"

emcc -o "$OUT_DIR/index.html" \
	"$OUT_DIR/game.wasm.o" \
	"$ODIN_PATH/vendor/raylib/wasm/libraylib.web.a" \
	-sUSE_GLFW=3 \
	-sWASM_BIGINT \
	-sALLOW_MEMORY_GROWTH \
	-sWARN_ON_UNDEFINED_SYMBOLS=0 \
	-sEXPORTED_RUNTIME_METHODS=HEAPF32 \
	--shell-file web/index_template.html

rm "$OUT_DIR/game.wasm.o"
echo "Web build created in $OUT_DIR"
