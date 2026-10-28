#+build windows, linux
package main

import rl "vendor:raylib"

// Title bar and taskbar icon. The .exe icon in Explorer comes from sudoku.rc,
// linked by the Windows build (-resource).
set_window_icon :: proc() {
	icon := rl.LoadImageFromMemory(".png", raw_data(ICON_DATA), i32(len(ICON_DATA)))
	defer rl.UnloadImage(icon)
	rl.SetWindowIcon(icon)
}
