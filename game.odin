package main

import rl "vendor:raylib"

Game :: struct {
	camera: rl.Camera2D,
}

update :: proc(game: ^Game) {
	events()
	game.camera = make_camera()
}

draw :: proc(game: Game) {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.LIGHTGRAY)

	rl.BeginMode2D(game.camera)
	draw_grid(game.camera.zoom)
	rl.EndMode2D()

	draw_hud()
}

@(private = "file")
events :: proc() {
	if rl.IsKeyPressed(.F11) {
		rl.ToggleBorderlessWindowed()
	}
}
