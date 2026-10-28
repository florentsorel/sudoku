package main

import "puzzle"
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

		r, c := game.selected[0], game.selected[1]

		// Digit keys 1-9 (top row or keypad) write into the selected cell
		for i in 0 ..< 9 {
			top_row := rl.KeyboardKey(int(rl.KeyboardKey.ONE) + i)
			keypad := rl.KeyboardKey(int(rl.KeyboardKey.KP_1) + i)
			if rl.IsKeyPressed(top_row) || rl.IsKeyPressed(keypad) {
				puzzle.set(&game.board, r, c, u8(i + 1))
			}
		}

		// Delete value in cell
		if rl.IsKeyPressed(.DELETE) || rl.IsKeyPressed(.BACKSPACE) {
			puzzle.set(&game.board, r, c, 0)
		}
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
