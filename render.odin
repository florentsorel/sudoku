package main

import rl "vendor:raylib"

GRID_SIZE :: 900
CELL_SIZE :: GRID_SIZE / 9
MARGIN :: 40
DIGIT_SIZE :: 60

@(private = "file")
DIGITS := [10]cstring{"", "1", "2", "3", "4", "5", "6", "7", "8", "9"}

draw_grid :: proc(zoom: f32) {
	// Thin first, thicker after
	for i in 0 ..= 9 {
		if i % 3 != 0 do draw_grid_line(i, max(1.5, 1 / zoom), rl.DARKGRAY)
	}
	for i in 0 ..= 9 {
		if i % 3 == 0 do draw_grid_line(i, max(4, 2 / zoom), rl.BLACK)
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
		rl.GRAY,
	)
}

draw_board :: proc(game: Game) {
	board := game.board
	for r in 0 ..< 9 {
		for c in 0 ..< 9 {
			v := board.cells[r][c]
			if v == 0 do continue
			color := rl.BLACK if board.given[r][c] else rl.DARKBLUE
			draw_digit(game.font, r, c, v, color)
		}
	}
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

	x := f32(c) * CELL_SIZE + (CELL_SIZE - ink_w) / 2 - ink_x
	y := f32(r) * CELL_SIZE + (CELL_SIZE - ink_h) / 2 - ink_y
	rl.DrawTextEx(font, DIGITS[v], {x, y}, DIGIT_SIZE, 0, color)
}
