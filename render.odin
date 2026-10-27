package main

import rl "vendor:raylib"

GRID_SIZE :: 900
CELL_SIZE :: GRID_SIZE / 9
MARGIN :: 40

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

draw_grid :: proc(zoom: f32) {
	// Thin first, thicker after
	for i in 0 ..= 9 {
		if i % 3 != 0 do draw_grid_line(i, max(1.5, 1 / zoom), rl.DARKGRAY)
	}
	for i in 0 ..= 9 {
		if i % 3 == 0 do draw_grid_line(i, max(4, 2 / zoom), rl.BLACK)
	}
}

draw_hud :: proc() {
	ui := ui_scale()
	size := i32(20 * ui)
	margin := i32(10 * ui)
	text: cstring = "F11 - Full screen"
	w := rl.MeasureText(text, size)
	rl.DrawText(text, rl.GetScreenWidth() - w - margin, margin, size, rl.GRAY)
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
