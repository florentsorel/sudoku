package main

import "core:fmt"
import "core:math/rand"
import "puzzle"
import rl "vendor:raylib"

Screen :: enum {
	Menu,
	Playing,
	Won,
}

// Everything the program keeps between frames
Game :: struct {
	screen:      Screen,
	camera:      rl.Camera2D,
	font:        rl.Font,
	sounds:      Sounds,
	play:        Play, // the current puzzle, replaced by new_game
	in_progress: bool, // a puzzle is started and not solved: the menu offers Continue
	menu_focus:  int, // index of the highlighted menu button
	settings:    Settings, // player preferences, kept across games and restarts
	quit:        bool,
}

// Zero values are the defaults, so a missing settings file means "everything on"
Settings :: struct {
	hide_highlights: bool, // no yellow row/column/box, no blue same-digit cells
}

// G key or menu button: flip the highlights and remember the choice
toggle_highlights :: proc(game: ^Game) {
	game.settings.hide_highlights = !game.settings.hide_highlights
	save_settings(game.settings)
}

// One puzzle being played. Reset as a whole when a new game starts.
Play :: struct {
	board:         puzzle.Board,
	difficulty:    puzzle.Difficulty,
	seed:          u64, // replays the exact same puzzle
	selected:      [2]int,
	has_selection: bool,
	hovered:       [2]int,
	has_hover:     bool,
	note_mode:     bool, // digit keys toggle pencil notes instead of writing
	elapsed:       f32, // seconds spent on the puzzle, paused when the window loses focus
	hints:         int, // hints that changed a cell, shown on the win screen
	history:       [dynamic]puzzle.Board, // boards before each edit, for undo
	flash:         [puzzle.UNIT_COUNT]f32, // seconds left of each "unit completed" flash
	won_anim:      f32, // seconds since the win screen appeared
	debug_solved:  bool, // F3: grid filled by the solver
}

FLASH_TIME :: 0.6

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

// Is this the browser build? The web page owns the window there: no full screen
// toggle, no Quit button, and the canvas is resized from JavaScript.
IS_WEB :: ODIN_OS == .JS

// Embedded in the executable: no assets folder to ship next to it
FONT_DATA :: #load("assets/fonts/Inter_28pt-Medium.ttf")

// Window, audio, assets and the saved state. Shared by the desktop main
// (main.odin) and the web entry points (main_web.odin).
init :: proc(game: ^Game) {
	flags: rl.ConfigFlags = {.VSYNC_HINT, .WINDOW_RESIZABLE}
	when !IS_WEB do flags += {.WINDOW_HIGHDPI}
	rl.SetConfigFlags(flags)
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Sudoku")
	rl.SetWindowMinSize(640, 360)
	rl.SetExitKey(.KEY_NULL) // Esc goes back to the menu instead of closing the window
	rl.InitAudioDevice()

	font_data := FONT_DATA
	game.font = rl.LoadFontFromMemory(
		".ttf",
		raw_data(font_data),
		i32(len(font_data)),
		128,
		nil,
		0,
	)
	rl.SetTextureFilter(game.font.texture, .BILINEAR)
	game.sounds = load_sounds()

	game.settings = load_settings()
	if data, ok := load_game(); ok do resume(game, data)
}

// One frame. false when the game wants to stop.
frame :: proc(game: ^Game) -> bool {
	update(game)
	draw(game^)

	// Throwaway strings (fmt.ctprintf...) live one frame
	free_all(context.temp_allocator)

	// Never asked on the web: WindowShouldClose sleeps 16 ms there
	when !IS_WEB do if rl.WindowShouldClose() do return false
	return !game.quit
}

shutdown :: proc(game: ^Game) {
	// Keep an unfinished puzzle for next time
	if game.in_progress do save_game(game.play)

	delete(game.play.history)
	unload_sounds(game.sounds)
	rl.UnloadFont(game.font)
	rl.CloseAudioDevice()
	rl.CloseWindow()
}

update :: proc(game: ^Game) {
	// Global keys: active on every screen
	when !IS_WEB do if rl.IsKeyPressed(.F11) do rl.ToggleBorderlessWindowed()
	game.camera = make_camera() // after F11, which may resize the window

	switch game.screen {
	case .Menu:
		update_menu(game)
	case .Playing:
		update_play(game)
	case .Won:
		update_won(game)
	}
}

draw :: proc(game: Game) {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(BACKGROUND_COLOR)

	switch game.screen {
	case .Menu:
		draw_menu(game)
	case .Playing:
		draw_play(game)
	case .Won:
		draw_won(game)
	}
}

// Fresh random puzzle; the previous one is discarded
new_game :: proc(game: ^Game, difficulty: puzzle.Difficulty) {
	delete(game.play.history)
	game.play = {}
	game.play.difficulty = difficulty
	game.play.seed = rand.uint64()
	game.play.board = puzzle.generate(difficulty, game.play.seed)
	game.in_progress = true
	game.screen = .Playing
}

// mm:ss, allocated in the temp allocator
format_time :: proc(seconds: f32) -> cstring {
	s := int(seconds)
	return fmt.ctprintf("%02d:%02d", s / 60, s % 60)
}

// Cmd on macOS, Ctrl elsewhere: both accepted everywhere
command_down :: proc() -> bool {
	return(
		rl.IsKeyDown(.LEFT_CONTROL) ||
		rl.IsKeyDown(.RIGHT_CONTROL) ||
		rl.IsKeyDown(.LEFT_SUPER) ||
		rl.IsKeyDown(.RIGHT_SUPER) \
	)
}
