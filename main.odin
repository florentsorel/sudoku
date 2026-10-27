package main

import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_HIGHDPI})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Sudoku")
	defer rl.CloseWindow()

	rl.SetWindowMinSize(640, 360)

	game := Game{}
	for !rl.WindowShouldClose() {
		update(&game)
		draw(game)
	}
}
