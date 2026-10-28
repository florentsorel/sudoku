package main

import "core:fmt"
import "puzzle"
import rl "vendor:raylib"

update_play :: proc(game: ^Game) {
	play := &game.play
	dt := rl.GetFrameTime()

	// Esc: back to the menu, the puzzle is kept for Continue
	if rl.IsKeyPressed(.ESCAPE) {
		save_game(play^)
		game.menu_focus = 0
		game.screen = .Menu
		return
	}

	// Cmd/Ctrl+R: new puzzle, same difficulty
	if command_down() && rl.IsKeyPressed(.R) {
		new_game(game, play.difficulty)
		return
	}

	keyboard_events(game)
	mouse_events(game)

	// The clock only runs while the player can actually see the grid
	if rl.IsWindowFocused() do play.elapsed += dt
	for &t in play.flash do t = max(t - dt, 0)

	when ODIN_DEBUG {
		// F2: show the win screen without solving
		if rl.IsKeyPressed(.F2) {
			game.screen = .Won
			return
		}
		// F3: solve the grid from its given digits
		if rl.IsKeyPressed(.F3) {
			if cells, ok := puzzle.solution(play.board); ok {
				append(&play.history, play.board)
				play.board.cells = cells
				play.debug_solved = true
			}
		}
	}

	if puzzle.is_solved(&play.board.cells) {
		game.screen = .Won
		game.in_progress = false
		play.won_anim = 0
		delete_save()
		rl.PlaySound(game.sounds.win)
	}
}

draw_play :: proc(game: Game, show_selection := true) {
	play := game.play

	rl.BeginMode2D(game.camera)
	draw_flashes(play)
	if show_selection do draw_selection(play, game.settings)
	draw_grid(game.camera.zoom)
	draw_board(game.font, play.board)
	rl.EndMode2D()

	draw_play_hud(game)
}

// Clock and mode top-left, controls bottom-left, full screen hint top-right
@(private = "file")
draw_play_hud :: proc(game: Game) {
	play := game.play
	ui := ui_scale()
	margin := 16 * ui
	w, h := f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

	// Top-left: clock, difficulty, note mode
	y := margin
	draw_text(game.font, format_time(play.elapsed), {margin, y}, 40 * ui, HUD_STRONG_COLOR)
	y += 46 * ui
	draw_text(game.font, fmt.ctprintf("%v", play.difficulty), {margin, y}, 20 * ui, HUD_TEXT_COLOR)
	y += 28 * ui
	if play.note_mode {
		draw_text(game.font, "Notes ON", {margin, y}, 20 * ui, WIN_ACCENT)
	}
	when ODIN_DEBUG {
		draw_text(
			game.font,
			fmt.ctprintf("seed %v", play.seed),
			{margin, y + 28 * ui},
			14 * ui,
			HUD_TEXT_COLOR,
		)
	}

	// Bottom-left: controls, one per line
	HELP :: [?]cstring {
		"1-9  write",
		"N  notes",
		"H  hint",
		"G  highlights on/off",
		"U / Cmd+Z  undo",
		"Cmd+R  new puzzle",
		"Esc  menu",
	}
	size := 16 * ui
	line := 22 * ui
	y = h - margin - f32(len(HELP)) * line
	for text in HELP {
		draw_text(game.font, text, {margin, y}, size, HUD_TEXT_COLOR)
		y += line
	}

	// Top-right
	text: cstring = "F11  full screen"
	dim := rl.MeasureTextEx(game.font, text, size, 0)
	draw_text(game.font, text, {w - dim.x - margin, margin}, size, HUD_TEXT_COLOR)
}
