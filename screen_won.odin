package main

import "core:fmt"
import rl "vendor:raylib"

WON_FADE_TIME :: 0.35

update_won :: proc(game: ^Game) {
	game.play.won_anim += rl.GetFrameTime()

	// Enter, Space or a click: next puzzle, same difficulty
	if rl.IsKeyPressed(.ENTER) ||
	   rl.IsKeyPressed(.KP_ENTER) ||
	   rl.IsKeyPressed(.SPACE) ||
	   rl.IsMouseButtonPressed(.LEFT) {
		new_game(game, game.play.difficulty)
		return
	}
	if rl.IsKeyPressed(.ESCAPE) {
		game.menu_focus = 0
		game.screen = .Menu
	}

	when ODIN_DEBUG {
		// F2: back to the grid (pairs with F2 on the play screen)
		if rl.IsKeyPressed(.F2) do game.screen = .Playing
	}
}

draw_won :: proc(game: Game) {
	draw_play(game, show_selection = false)
	k := min(game.play.won_anim / WON_FADE_TIME, 1)
	draw_card(
		game.font,
		"Well done!",
		win_subtitle(game.play),
		"Enter: next puzzle    Esc: menu",
		k,
	)
}

// How the grid was solved. Allocated in the temp allocator.
@(private = "file")
win_subtitle :: proc(play: Play) -> cstring {
	time := format_time(play.elapsed)
	switch {
	case play.debug_solved:
		return "Solved by the solver (debug)"
	case play.hints == 1:
		return fmt.ctprintf("Solved in %v with 1 hint", time)
	case play.hints > 1:
		return fmt.ctprintf("Solved in %v with %d hints", time, play.hints)
	}
	return fmt.ctprintf("Solved in %v", time)
}
