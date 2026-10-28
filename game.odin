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

update :: proc(game: ^Game) {
	// Global keys: active on every screen
	if rl.IsKeyPressed(.F11) do rl.ToggleBorderlessWindowed()
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
