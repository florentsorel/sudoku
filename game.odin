package main

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
	debug:         Debug,
}

Debug :: struct {
	won: bool,
}

// Real win or forced by the debug key
is_won :: proc(game: Game) -> bool {
	return game.won || game.debug.won
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
	rl.ClearBackground(rl.LIGHTGRAY)

	won := is_won(game)

	rl.BeginMode2D(game.camera)
	if !won do draw_selection(game)
	draw_grid(game.camera.zoom)
	draw_board(game)
	rl.EndMode2D()

	draw_won(game.font, won)

	draw_hud(game.font)
}
