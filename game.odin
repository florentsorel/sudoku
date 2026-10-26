package main

import rl "vendor:raylib"

Game :: struct {}

update :: proc(game: ^Game) {

}

draw :: proc(game: Game) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.LIGHTGRAY)

	rl.EndDrawing()
}
