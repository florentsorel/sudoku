package main

import "puzzle"
import rl "vendor:raylib"

GRID_SIZE :: 900
CELL_SIZE :: GRID_SIZE / 9
MARGIN :: 40
DIGIT_SIZE :: 60
NOTE_SIZE :: 26

// Palette. Fade() can't be used in constants, so alphas are written out (0-255)
BACKGROUND_COLOR :: rl.LIGHTGRAY
GRID_THIN_COLOR :: rl.DARKGRAY
GRID_THICK_COLOR :: rl.BLACK

DIGIT_GIVEN_COLOR :: rl.BLACK
DIGIT_PLAYER_COLOR :: rl.DARKBLUE
DIGIT_CONFLICT_COLOR :: rl.RED
NOTE_COLOR :: rl.Color{70, 70, 70, 255}

SELECTED_COLOR :: rl.Color{253, 249, 0, 100} // yellow, 39%
PEER_COLOR :: rl.Color{253, 249, 0, 25} // yellow, 10%
SAME_DIGIT_COLOR :: rl.Color{0, 121, 241, 45} // blue, 18%
HOVER_COLOR :: rl.Color{0, 0, 0, 15} // black, 6%
FLASH_COLOR :: rl.Color{47, 122, 79, 110} // green, 43% at the start of the flash

HUD_TEXT_COLOR :: rl.GRAY
HUD_STRONG_COLOR :: rl.Color{40, 40, 40, 255}
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

draw_board :: proc(font: rl.Font, board: puzzle.Board) {
	board := board // local copy: is_valid needs an address
	for r in 0 ..< 9 {
		for c in 0 ..< 9 {
			v := board.cells[r][c]
			if v == 0 {
				draw_notes(font, board.notes[r][c], r, c)
				continue
			}

			color: rl.Color
			switch {
			case board.given[r][c]:
				color = DIGIT_GIVEN_COLOR
			case !puzzle.is_valid(&board.cells, r, c, v):
				color = DIGIT_CONFLICT_COLOR
			case:
				color = DIGIT_PLAYER_COLOR
			}

			draw_digit(font, v, cell_rect(r, c), DIGIT_SIZE, color)
		}
	}
}

// With hide_highlights, only the selected and hovered cells are shown
draw_selection :: proc(play: Play, settings: Settings) {
	assist := !settings.hide_highlights
	selected_v: u8
	if play.has_selection do selected_v = play.board.cells[play.selected[0]][play.selected[1]]

	// Each cell is drawn at most once, so translucent colors never stack
	for r in 0 ..< 9 {
		for c in 0 ..< 9 {
			cell := [2]int{r, c}
			is_selected := play.has_selection && cell == play.selected
			is_hovered := play.has_hover && cell == play.hovered
			is_peer := assist && play.has_selection && puzzle.is_peer(cell, play.selected)
			same_digit := assist && selected_v != 0 && play.board.cells[r][c] == selected_v

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

// Rows, columns and boxes that were just completed light up, then fade out
draw_flashes :: proc(play: Play) {
	for unit in 0 ..< puzzle.UNIT_COUNT {
		t := play.flash[unit]
		if t <= 0 do continue
		color := scale_alpha(FLASH_COLOR, t / FLASH_TIME)
		for cell in puzzle.unit_cells(unit) do rl.DrawRectangleRec(cell_rect(cell[0], cell[1]), color)
	}
}

// Centered card: a title and two lines below. k (0-1) fades and slides it in.
draw_card :: proc(font: rl.Font, title, line1, line2: cstring, k: f32) {
	ui := ui_scale()
	w, h := f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

	// Dim what's behind, keep it visible
	rl.DrawRectangleRec({0, 0, w, h}, scale_alpha(WIN_OVERLAY_COLOR, k))

	title_size := 64 * ui
	line1_size := 24 * ui
	line2_size := 18 * ui
	title_dim := rl.MeasureTextEx(font, title, title_size, 0)
	line1_dim := rl.MeasureTextEx(font, line1, line1_size, 0)
	line2_dim := rl.MeasureTextEx(font, line2, line2_size, 0)

	// Card sized from its content
	pad := 40 * ui
	gap := 8 * ui
	card_w := max(title_dim.x, line1_dim.x, line2_dim.x) + 2 * pad
	card_h := title_dim.y + gap + line1_dim.y + 3 * gap + line2_dim.y + 2 * pad
	slide := (1 - k) * 24 * ui
	card := rl.Rectangle{(w - card_w) / 2, (h - card_h) / 2 + slide, card_w, card_h}

	// Soft shadow slightly offset, then the card itself
	shadow := card
	shadow.x += 6 * ui
	shadow.y += 8 * ui
	rl.DrawRectangleRounded(shadow, 0.25, 16, scale_alpha(WIN_SHADOW_COLOR, k))
	rl.DrawRectangleRounded(card, 0.25, 16, scale_alpha(WIN_CARD_COLOR, k))

	// Every line centered in the card
	y := card.y + pad
	draw_text(
		font,
		title,
		{card.x + (card_w - title_dim.x) / 2, y},
		title_size,
		scale_alpha(WIN_ACCENT, k),
	)
	y += title_dim.y + gap
	draw_text(
		font,
		line1,
		{card.x + (card_w - line1_dim.x) / 2, y},
		line1_size,
		scale_alpha(WIN_SUBTITLE_COLOR, k),
	)
	y += line1_dim.y + 3 * gap
	draw_text(
		font,
		line2,
		{card.x + (card_w - line2_dim.x) / 2, y},
		line2_size,
		scale_alpha(HUD_TEXT_COLOR, k),
	)
}

// Screen-space text, position in logical pixels
draw_text :: proc(font: rl.Font, text: cstring, pos: rl.Vector2, size: f32, color: rl.Color) {
	rl.DrawTextEx(font, text, pos, size, 0, color)
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

// Same color, alpha multiplied by k (0-1)
scale_alpha :: proc(color: rl.Color, k: f32) -> rl.Color {
	c := color
	c.a = u8(f32(c.a) * clamp(k, 0, 1))
	return c
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

// Pencil notes: small digits on a 3×3 layout inside the cell, 1 top-left to 9 bottom-right
@(private = "file")
draw_notes :: proc(font: rl.Font, notes: puzzle.Digits, r, c: int) {
	cell := cell_rect(r, c)
	sub := f32(CELL_SIZE) / 3
	for n in notes {
		i := n - 1
		rect := rl.Rectangle{cell.x + f32(i % 3) * sub, cell.y + f32(i / 3) * sub, sub, sub}
		draw_digit(font, u8(n), rect, NOTE_SIZE, NOTE_COLOR)
	}
}

// Digit centered in rect by its ink, not its text box, so 1 and 7 look centered too
@(private = "file")
draw_digit :: proc(font: rl.Font, v: u8, rect: rl.Rectangle, size: f32, color: rl.Color) {
	ch := rune('0' + v)
	scale := size / f32(font.baseSize)

	rec := rl.GetGlyphAtlasRec(font, ch)
	info := rl.GetGlyphInfo(font, ch)
	ink_w := rec.width * scale
	ink_h := rec.height * scale
	ink_x := f32(info.offsetX) * scale
	ink_y := f32(info.offsetY) * scale

	x := rect.x + (rect.width - ink_w) / 2 - ink_x
	y := rect.y + (rect.height - ink_h) / 2 - ink_y
	rl.DrawTextEx(font, DIGITS[v], {x, y}, size, 0, color)
}
