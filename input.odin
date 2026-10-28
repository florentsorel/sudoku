package main

import "puzzle"
import rl "vendor:raylib"

// Play screen keys. Letters and digits are physical key positions (US layout names):
// on AZERTY, .Z is the key labelled W, hence U as a layout-proof undo.
@(private)
keyboard_events :: proc(game: ^Game) {
	play := &game.play

	if rl.IsKeyPressed(.U) || (command_down() && rl.IsKeyPressed(.Z)) {
		if undo(play) do save_game(play^)
	}
	if rl.IsKeyPressed(.N) do play.note_mode = !play.note_mode
	if rl.IsKeyPressed(.G) do toggle_highlights(game)

	if !play.has_selection do return

	if rl.IsKeyPressed(.LEFT) || rl.IsKeyPressedRepeat(.LEFT) do play.selected[1] -= 1
	if rl.IsKeyPressed(.RIGHT) || rl.IsKeyPressedRepeat(.RIGHT) do play.selected[1] += 1
	if rl.IsKeyPressed(.UP) || rl.IsKeyPressedRepeat(.UP) do play.selected[0] -= 1
	if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressedRepeat(.DOWN) do play.selected[0] += 1

	play.selected[0] = clamp(play.selected[0], 0, 8)
	play.selected[1] = clamp(play.selected[1], 0, 8)

	r, c := play.selected[0], play.selected[1]

	// Digit keys 1-9 (top row or keypad): write, or toggle a note in note mode
	for i in 0 ..< 9 {
		top_row := rl.KeyboardKey(int(rl.KeyboardKey.ONE) + i)
		keypad := rl.KeyboardKey(int(rl.KeyboardKey.KP_1) + i)
		if rl.IsKeyPressed(top_row) || rl.IsKeyPressed(keypad) {
			if play.note_mode {
				toggle_note(game, r, c, u8(i + 1))
			} else {
				write(game, r, c, u8(i + 1))
			}
		}
	}

	// Delete value in cell
	if rl.IsKeyPressed(.DELETE) || rl.IsKeyPressed(.BACKSPACE) do write(game, r, c, 0)

	// Hint: reveal the right digit in the selected cell
	if rl.IsKeyPressed(.H) do hint(game, r, c)
}

@(private)
mouse_events :: proc(game: ^Game) {
	play := &game.play
	r, c, ok := mouse_cell(game.camera)

	// Updated every frame, so the hover disappears when the mouse leaves the grid
	play.hovered = {r, c}
	play.has_hover = ok

	if ok && rl.IsMouseButtonPressed(.LEFT) {
		play.selected = {r, c}
		play.has_selection = true
	}
}

// Write a digit (0 clears), with undo, sound and completion flashes
@(private = "file")
write :: proc(game: ^Game, r, c: int, v: u8) {
	play := &game.play
	before := play.board
	if !puzzle.set(&play.board, r, c, v) {
		rl.PlaySound(game.sounds.error) // given cell: can't be changed
		return
	}
	if !record(play, before) do return
	save_game(play^) // autosave: a crash or a closed tab loses nothing
	if v == 0 do return

	if puzzle.is_valid(&play.board.cells, r, c, v) {
		rl.PlaySound(game.sounds.place)
		start_flashes(play, before)
	} else {
		rl.PlaySound(game.sounds.error)
	}
}

@(private = "file")
toggle_note :: proc(game: ^Game, r, c: int, n: u8) {
	play := &game.play
	before := play.board
	if puzzle.toggle_note(&play.board, r, c, n) && record(play, before) {
		save_game(play^)
		rl.PlaySound(game.sounds.note)
	}
}

@(private = "file")
hint :: proc(game: ^Game, r, c: int) {
	play := &game.play
	before := play.board
	if puzzle.hint(&play.board, r, c) && record(play, before) {
		play.hints += 1 // only counted when the hint changed something
		save_game(play^)
		rl.PlaySound(game.sounds.place)
		start_flashes(play, before)
	}
}

// Flash every row, column and box this edit completed
@(private = "file")
start_flashes :: proc(play: ^Play, before: puzzle.Board) {
	prev := before // local copy: is_unit_complete needs an address
	for unit in 0 ..< puzzle.UNIT_COUNT {
		was := puzzle.is_unit_complete(&prev.cells, unit)
		now := puzzle.is_unit_complete(&play.board.cells, unit)
		if now && !was do play.flash[unit] = FLASH_TIME
	}
}

@(private = "file")
mouse_cell :: proc(camera: rl.Camera2D) -> (r, c: int, ok: bool) {
	// Mouse in logical pixels, camera in framebuffer pixels: scale by their ratio.
	// 2 on a Retina screen with WINDOW_HIGHDPI, 1 elsewhere (including the web build).
	scale := f32(rl.GetRenderWidth()) / f32(rl.GetScreenWidth())
	mp := rl.GetMousePosition() * scale
	world := rl.GetScreenToWorld2D(mp, camera)

	if world.x < 0 || world.y < 0 do return
	r, c = int(world.y) / CELL_SIZE, int(world.x) / CELL_SIZE
	ok = r < 9 && c < 9
	return
}
