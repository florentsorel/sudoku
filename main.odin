package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

// fmt and mem are only used in debug builds (when ODIN_DEBUG): keep the imports valid in release
_ :: fmt
_ :: mem

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

// Embedded in the executable: no assets folder to ship next to it
FONT_DATA :: #load("assets/fonts/Inter_28pt-Medium.ttf")

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

	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_HIGHDPI})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Sudoku")
	defer rl.CloseWindow()
	rl.SetWindowMinSize(640, 360)
	rl.SetExitKey(.KEY_NULL) // Esc goes back to the menu instead of closing the window

	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()

	game: Game
	defer delete(game.play.history)

	font_data := FONT_DATA
	game.font = rl.LoadFontFromMemory(
		".ttf",
		raw_data(font_data),
		i32(len(font_data)),
		128,
		nil,
		0,
	)
	defer rl.UnloadFont(game.font)
	rl.SetTextureFilter(game.font.texture, .BILINEAR)

	game.sounds = load_sounds()
	defer unload_sounds(game.sounds)

	game.settings = load_settings()
	if data, ok := load_game(); ok do resume(&game, data)

	for !rl.WindowShouldClose() && !game.quit {
		update(&game)
		draw(game)

		// Throwaway strings (fmt.ctprintf...) live one frame
		free_all(context.temp_allocator)
	}

	// Keep an unfinished puzzle for next time
	if game.in_progress do save_game(game.play)
}
