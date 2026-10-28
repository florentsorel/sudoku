package main

import "core:fmt"
import "puzzle"
import rl "vendor:raylib"

SAMPLE :: `
53. .7. ...
6.. 195 ...
.98 ... .6.
8.. .6. ..3
4.. 8.3 ..1
7.. .2. ..6
.6. ... 28.
... 419 ..5
... .8. .79
`

Game :: struct {
	camera:        rl.Camera2D,
	board:         puzzle.Board,
	font:          rl.Font,
	selected:      [2]int,
	has_selection: bool,
	hovered:       [2]int,
	has_hover:     bool,
	won:           bool,
	hints:         int, // hints that changed a cell, shown on the win screen
	debug:         Debug,
}

Debug :: struct {
	won:    bool, // F2: win screen forced
	solved: bool, // F3: grid filled by the solver
}

// Real win or forced by the debug key
is_won :: proc(game: Game) -> bool {
	return game.won || game.debug.won
}

// How the grid was solved, for the win screen. Allocated in the temp allocator.
win_subtitle :: proc(game: Game) -> cstring {
	switch {
	case game.debug.solved:
		return "Solved by the solver (debug)"
	case game.hints == 1:
		return "Solved with 1 hint"
	case game.hints > 1:
		return fmt.ctprintf("Solved with %d hints", game.hints)
	}
	return "Solved"
}

update :: proc(game: ^Game) {
	keyboard_events(game)
	game.camera = make_camera()
	mouse_events(game)
	game.won = puzzle.is_solved(&game.board.cells)
}

draw :: proc(game: Game) {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(BACKGROUND_COLOR)

	won := is_won(game)

	rl.BeginMode2D(game.camera)
	if !won do draw_selection(game)
	draw_grid(game.camera.zoom)
	draw_board(game)
	rl.EndMode2D()

	if won do draw_won(game.font, win_subtitle(game))

	draw_hud(game.font)
}
