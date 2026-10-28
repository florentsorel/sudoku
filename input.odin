package main

import rl "vendor:raylib"


@(private)
keyboard_events :: proc() {
	if rl.IsKeyPressed(.F11) {
		rl.ToggleBorderlessWindowed()
	}
}

@(private)
mouse_events :: proc(game: ^Game) {
	r, c, ok := mouse_cell(game.camera)

	// Updated every frame, so the hover disappears when the mouse leaves the grid
	game.hovered = {r, c}
	game.has_hover = ok

	if ok && rl.IsMouseButtonPressed(.LEFT) {
		game.selected = {r, c}
		game.has_selection = true
	}
}

@(private = "file")
mouse_cell :: proc(camera: rl.Camera2D) -> (r, c: int, ok: bool) {
	mp := rl.GetMousePosition() * rl.GetWindowScaleDPI()
	world := rl.GetScreenToWorld2D(mp, camera)

	if world.x < 0 || world.y < 0 do return
	r, c = int(world.y) / CELL_SIZE, int(world.x) / CELL_SIZE
	ok = r < 9 && c < 9
	return
}
