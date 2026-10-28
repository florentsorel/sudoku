package main

import rl "vendor:raylib"


@(private)
keyboard_events :: proc(game: ^Game) {
	if rl.IsKeyPressed(.F11) {
		rl.ToggleBorderlessWindowed()
	}

	// Change cell selection
	if game.has_selection {
		if rl.IsKeyPressed(.LEFT) || rl.IsKeyPressedRepeat(.LEFT) do game.selected[1] -= 1
		if rl.IsKeyPressed(.RIGHT) || rl.IsKeyPressedRepeat(.RIGHT) do game.selected[1] += 1
		if rl.IsKeyPressed(.UP) || rl.IsKeyPressedRepeat(.UP) do game.selected[0] -= 1
		if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressedRepeat(.DOWN) do game.selected[0] += 1

		game.selected[0] = clamp(game.selected[0], 0, 8)
		game.selected[1] = clamp(game.selected[1], 0, 8)

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
