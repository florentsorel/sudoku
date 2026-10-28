#+build !js
package main

import "core:fmt"
import "core:mem"

// fmt and mem are only used in debug builds (when ODIN_DEBUG): keep the imports valid in release
_ :: fmt
_ :: mem

// Desktop entry point. The web one is in main_web.odin.
main :: proc() {
	// Debug builds report every allocation never freed
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer {
			for _, leak in track.allocation_map do fmt.eprintfln("leak: %v bytes at %v", leak.size, leak.location)
			mem.tracking_allocator_destroy(&track)
		}
	}

	game: Game
	init(&game)
	for frame(&game) {}
	shutdown(&game)
}
