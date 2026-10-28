package main

import "puzzle"
import rl "vendor:raylib"

Menu_Item :: enum {
	Continue,
	Easy,
	Medium,
	Hard,
	Highlights,
	Quit,
}

MENU_LABELS := [Menu_Item]cstring {
	.Continue   = "Continue",
	.Easy       = "New game: Easy",
	.Medium     = "New game: Medium",
	.Hard       = "New game: Hard",
	.Highlights = "", // depends on the setting, see menu_label
	.Quit       = "Quit",
}

MENU_BUTTON_COLOR :: rl.RAYWHITE
MENU_TEXT_COLOR :: rl.Color{40, 40, 40, 255}

update_menu :: proc(game: ^Game) {
	items, count := menu_items(game^)
	game.menu_focus = clamp(game.menu_focus, 0, count - 1)

	// Keyboard: arrows move the focus, wrapping around
	if rl.IsKeyPressed(.DOWN) do game.menu_focus = (game.menu_focus + 1) % count
	if rl.IsKeyPressed(.UP) do game.menu_focus = (game.menu_focus - 1 + count) % count
	activate := rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.KP_ENTER) || rl.IsKeyPressed(.SPACE)

	// Mouse: hovering moves the focus, but only when the mouse moves,
	// so a cursor resting on a button doesn't fight the arrow keys
	mouse := rl.GetMousePosition()
	moved := rl.GetMouseDelta() != {0, 0}
	for i in 0 ..< count {
		if !rl.CheckCollisionPointRec(mouse, menu_button_rect(i, count)) do continue
		if moved do game.menu_focus = i
		if rl.IsMouseButtonPressed(.LEFT) {
			game.menu_focus = i
			activate = true
		}
	}

	when !IS_WEB do if rl.IsKeyPressed(.ESCAPE) do game.quit = true
	if !activate do return

	switch items[game.menu_focus] {
	case .Continue:
		game.screen = .Playing
	case .Easy:
		new_game(game, puzzle.Difficulty.Easy)
	case .Medium:
		new_game(game, puzzle.Difficulty.Medium)
	case .Hard:
		new_game(game, puzzle.Difficulty.Hard)
	case .Highlights:
		toggle_highlights(game) // stays on the menu
	case .Quit:
		game.quit = true
	}
}

// Label of a button; the highlights one shows its current state
@(private = "file")
menu_label :: proc(game: Game, item: Menu_Item) -> cstring {
	if item == .Highlights {
		return "Highlights: off" if game.settings.hide_highlights else "Highlights: on"
	}
	return MENU_LABELS[item]
}

draw_menu :: proc(game: Game) {
	ui := ui_scale()
	w := f32(rl.GetScreenWidth())
	items, count := menu_items(game)

	// Title above the buttons
	title: cstring = "Sudoku"
	title_size := 96 * ui
	first := menu_button_rect(0, count)
	dim := rl.MeasureTextEx(game.font, title, title_size, 0)
	draw_text(
		game.font,
		title,
		{(w - dim.x) / 2, first.y - dim.y - 40 * ui},
		title_size,
		WIN_ACCENT,
	)

	for i in 0 ..< count {
		rect := menu_button_rect(i, count)
		focused := i == game.menu_focus
		fill := WIN_ACCENT if focused else MENU_BUTTON_COLOR
		ink := rl.RAYWHITE if focused else MENU_TEXT_COLOR

		rl.DrawRectangleRounded(rect, 0.3, 12, fill)
		label := menu_label(game, items[i])
		size := 24 * ui
		label_dim := rl.MeasureTextEx(game.font, label, size, 0)
		pos := rl.Vector2 {
			rect.x + (rect.width - label_dim.x) / 2,
			rect.y + (rect.height - label_dim.y) / 2,
		}
		draw_text(game.font, label, pos, size, ink)
	}
}

// Visible items, in order: Continue only when there is a puzzle to resume
@(private = "file")
menu_items :: proc(game: Game) -> (items: [len(Menu_Item)]Menu_Item, count: int) {
	for item in Menu_Item {
		if item == .Continue && !game.in_progress do continue
		if item == .Quit && IS_WEB do continue // a web page can't close itself
		items[count] = item
		count += 1
	}
	return
}

// Button i of count, as a column centered slightly below the middle of the screen.
// Shared by update (mouse hit test) and draw, so both always agree.
@(private = "file")
menu_button_rect :: proc(i, count: int) -> rl.Rectangle {
	ui := ui_scale()
	w, h := f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())
	bw, bh, gap := 340 * ui, 56 * ui, 14 * ui
	total := f32(count) * bh + f32(count - 1) * gap
	top := (h - total) / 2 + 60 * ui
	return {(w - bw) / 2, top + f32(i) * (bh + gap), bw, bh}
}
