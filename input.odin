package main

import "puzzle"
import rl "vendor:raylib"


@(private)
keyboard_events :: proc(game: ^Game) {
	// Global keys: always active, even on the win screen
	if rl.IsKeyPressed(.F11) {
		rl.ToggleBorderlessWindowed()
	}

	// Grid keys: locked once the puzzle is won
	if game.has_selection && !is_won(game^) {
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

		// Hint: reveal the right digit in the selected cell, counted only if it changed something
		if rl.IsKeyPressed(.H) {
			before := game.board.cells[r][c]
			if puzzle.hint(&game.board, r, c) && game.board.cells[r][c] != before do game.hints += 1
		}
	}

	// debug
	when ODIN_DEBUG {
		// F2: toggle the win screen without solving
		if rl.IsKeyPressed(.F2) do game.debug.won = !game.debug.won

		// F3: solve the grid from its given digits
		if rl.IsKeyPressed(.F3) {
			if cells, ok := puzzle.solution(game.board); ok {
				game.board.cells = cells
				game.debug.solved = true
			}
		}
	}
}

@(private)
mouse_events :: proc(game: ^Game) {
	// The grid is locked once the puzzle is won
	if is_won(game^) {
		game.has_hover = false
		return
	}

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
