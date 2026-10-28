package main

import "puzzle"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_HIGHDPI})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Sudoku")
	defer rl.CloseWindow()

	rl.SetWindowMinSize(640, 360)

	game: Game

	game.font = rl.LoadFontEx("assets/fonts/Inter_28pt-Medium.ttf", 128, nil, 0)
	defer rl.UnloadFont(game.font)
	rl.SetTextureFilter(game.font.texture, .BILINEAR)

	puzzle.load(&game.board, SAMPLE)

	for !rl.WindowShouldClose() {
		update(&game)
		draw(game)

		// Throwaway strings (fmt.ctprintf...) live one frame
		free_all(context.temp_allocator)
	}
}
