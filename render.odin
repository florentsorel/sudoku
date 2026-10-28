package main

import "puzzle"
import rl "vendor:raylib"

GRID_SIZE :: 900
CELL_SIZE :: GRID_SIZE / 9
MARGIN :: 40
DIGIT_SIZE :: 60

// Palette. Fade() can't be used in constants, so alphas are written out (0-255)
BACKGROUND_COLOR :: rl.LIGHTGRAY
GRID_THIN_COLOR :: rl.DARKGRAY
GRID_THICK_COLOR :: rl.BLACK

DIGIT_GIVEN_COLOR :: rl.BLACK
DIGIT_PLAYER_COLOR :: rl.DARKBLUE
DIGIT_CONFLICT_COLOR :: rl.RED

SELECTED_COLOR :: rl.Color{253, 249, 0, 63} // yellow, 25%
PEER_COLOR :: rl.Color{253, 249, 0, 25} // yellow, 10%
SAME_DIGIT_COLOR :: rl.Color{0, 121, 241, 45} // blue, 18%
HOVER_COLOR :: rl.Color{0, 0, 0, 15} // black, 6%

HUD_TEXT_COLOR :: rl.GRAY
WIN_OVERLAY_COLOR :: rl.Color{0, 0, 0, 114} // black, 45%
WIN_SHADOW_COLOR :: rl.Color{0, 0, 0, 63} // black, 25%
WIN_CARD_COLOR :: rl.RAYWHITE
WIN_ACCENT :: rl.Color{47, 122, 79, 255} // deep green
WIN_SUBTITLE_COLOR :: rl.GRAY

@(private = "file")
DIGITS := [10]cstring{"", "1", "2", "3", "4", "5", "6", "7", "8", "9"}

draw_grid :: proc(zoom: f32) {
	// Thin first, thicker after
	for i in 0 ..= 9 {
		if i % 3 != 0 do draw_grid_line(i, max(1.5, 1 / zoom), GRID_THIN_COLOR)
	}
	for i in 0 ..= 9 {
		if i % 3 == 0 do draw_grid_line(i, max(4, 2 / zoom), GRID_THICK_COLOR)
	}
}

draw_hud :: proc(font: rl.Font) {
	ui := ui_scale()
	size := f32(20 * ui)
	margin := f32(10 * ui)
	text: cstring = "F11 - Full screen"
	vec2 := rl.MeasureTextEx(font, text, size, 0)
	rl.DrawTextEx(
		font,
		text,
		{f32(rl.GetScreenWidth()) - vec2.x - margin, margin},
		size,
		0,
		HUD_TEXT_COLOR,
	)
}

draw_board :: proc(game: Game) {
	board := game.board
	for r in 0 ..< 9 {
		for c in 0 ..< 9 {
			v := board.cells[r][c]
			if v == 0 do continue
			conflict := !puzzle.is_valid(&board.cells, r, c, v)

			color: rl.Color
			switch {
			case board.given[r][c]:
				color = DIGIT_GIVEN_COLOR
			case conflict:
				color = DIGIT_CONFLICT_COLOR
			case:
				color = DIGIT_PLAYER_COLOR
			}

			draw_digit(game.font, r, c, v, color)
		}
	}
}

draw_selection :: proc(game: Game) {
	selected_v: u8

	if game.has_selection do selected_v = game.board.cells[game.selected[0]][game.selected[1]]

	// Each cell is drawn at most once, so translucent colors never stack
	for r in 0 ..< 9 {
		for c in 0 ..< 9 {
			cell := [2]int{r, c}
			is_selected := game.has_selection && cell == game.selected
			is_hovered := game.has_hover && cell == game.hovered
			is_peer := game.has_selection && puzzle.is_peer(cell, game.selected)
			same_digit := selected_v != 0 && game.board.cells[r][c] == selected_v

			// Priority: selected > hovered > same digit > peer
			if is_selected {
				rl.DrawRectangleRec(cell_rect(r, c), SELECTED_COLOR)
			} else if is_hovered {
				rl.DrawRectangleRec(cell_rect(r, c), HOVER_COLOR)
			} else if same_digit {
				rl.DrawRectangleRec(cell_rect(r, c), SAME_DIGIT_COLOR)
			} else if is_peer {
				rl.DrawRectangleRec(cell_rect(r, c), PEER_COLOR)
			}
		}
	}
}

draw_won :: proc(font: rl.Font, won: bool) {
	if !won do return
	ui := ui_scale()
	w, h := f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

	// Dim the grid, keep it visible
	rl.DrawRectangleRec({0, 0, w, h}, WIN_OVERLAY_COLOR)

	title: cstring = "Well done!"
	subtitle: cstring = "Solved"
	title_size := 64 * ui
	sub_size := 24 * ui
	title_dim := rl.MeasureTextEx(font, title, title_size, 0)
	sub_dim := rl.MeasureTextEx(font, subtitle, sub_size, 0)

	// Card sized from its content
	pad := 40 * ui
	gap := 8 * ui
	card_w := max(title_dim.x, sub_dim.x) + 2 * pad
	card_h := title_dim.y + gap + sub_dim.y + 2 * pad
	card := rl.Rectangle{(w - card_w) / 2, (h - card_h) / 2, card_w, card_h}

	// Soft shadow slightly offset, then the card itself
	shadow := card
	shadow.x += 6 * ui
	shadow.y += 8 * ui
	rl.DrawRectangleRounded(shadow, 0.25, 16, WIN_SHADOW_COLOR)
	rl.DrawRectangleRounded(card, 0.25, 16, WIN_CARD_COLOR)

	// Both lines centered in the card
	y := card.y + pad
	rl.DrawTextEx(font, title, {card.x + (card_w - title_dim.x) / 2, y}, title_size, 0, WIN_ACCENT)
	y += title_dim.y + gap
	rl.DrawTextEx(
		font,
		subtitle,
		{card.x + (card_w - sub_dim.x) / 2, y},
		sub_size,
		0,
		WIN_SUBTITLE_COLOR,
	)
}

make_camera :: proc() -> rl.Camera2D {
	// BeginMode2D drops the HiDPI scale: the camera works in framebuffer pixels
	w := f32(rl.GetRenderWidth())
	h := f32(rl.GetRenderHeight())
	return rl.Camera2D {
		zoom = min(w, h) / (GRID_SIZE + 2 * MARGIN),
		offset = {w / 2, h / 2},
		target = {GRID_SIZE / 2, GRID_SIZE / 2},
	}
}


ui_scale :: proc() -> f32 {
	return f32(min(rl.GetScreenWidth(), rl.GetScreenHeight())) / WINDOW_HEIGHT
}

// Cell (row, col) to its rectangle in world space: col gives x, row gives y
@(private = "file")
cell_rect :: proc(r, c: int) -> rl.Rectangle {
	return {f32(c) * CELL_SIZE, f32(r) * CELL_SIZE, CELL_SIZE, CELL_SIZE}
}

@(private = "file")
draw_grid_line :: proc(i: int, thickness: f32, color: rl.Color) {
	pos := f32(i) * CELL_SIZE
	half := thickness / 2

	rl.DrawLineEx(rl.Vector2{pos, -half}, rl.Vector2{pos, GRID_SIZE + half}, thickness, color)
	rl.DrawLineEx(rl.Vector2{-half, pos}, rl.Vector2{GRID_SIZE + half, pos}, thickness, color)

}

@(private = "file")
draw_digit :: proc(font: rl.Font, r, c: int, v: u8, color: rl.Color) {
	ch := rune('0' + v)
	scale := f32(DIGIT_SIZE) / f32(font.baseSize)

	rec := rl.GetGlyphAtlasRec(font, ch)
	info := rl.GetGlyphInfo(font, ch)
	ink_w := rec.width * scale
	ink_h := rec.height * scale
	ink_x := f32(info.offsetX) * scale
	ink_y := f32(info.offsetY) * scale

	cell := cell_rect(r, c)
	x := cell.x + (cell.width - ink_w) / 2 - ink_x
	y := cell.y + (cell.height - ink_h) / 2 - ink_y
	rl.DrawTextEx(font, DIGITS[v], {x, y}, DIGIT_SIZE, 0, color)
}
