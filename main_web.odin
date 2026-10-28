#+build js
package main

// Web entry points, called from JavaScript in web/index_template.html.
// The browser drives the loop (requestAnimationFrame) instead of a for loop.
// Based on karl-zylinski/odin-raylib-web.

import "base:runtime"
import "core:c"
import "core:mem"
import rl "vendor:raylib"

@(private = "file")
web_game: Game

@(private = "file")
web_context: runtime.Context

@(export)
main_start :: proc "c" () {
	context = runtime.default_context()
	// Odin's wasm allocator conflicts with emscripten's: use emscripten's malloc
	context.allocator = emscripten_allocator()
	runtime.init_global_temporary_allocator(1 * mem.Megabyte)
	web_context = context

	init(&web_game)
}

@(export)
main_update :: proc "c" () -> bool {
	context = web_context
	return frame(&web_game)
}

@(export)
main_end :: proc "c" () {
	context = web_context
	shutdown(&web_game)
}

// The page is closing or hidden: keep the puzzle in localStorage
@(export)
web_save :: proc "c" () {
	context = web_context
	if web_game.in_progress do save_game(web_game.play)
}

// The canvas fills the browser window
@(export)
web_window_size_changed :: proc "c" (w, h: c.int) {
	context = web_context
	rl.SetWindowSize(w, h)
}
