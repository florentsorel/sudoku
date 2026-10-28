package main

import "core:encoding/json"
import "puzzle"

// Saves and settings are JSON, stored by store_desktop.odin (files) or
// store_web.odin (browser localStorage).

// Bump when Save_Data changes shape: older saves are then ignored, not misread
SAVE_VERSION :: 1

SAVE_NAME :: "save.json"
SETTINGS_NAME :: "settings.json" // its own entry: deleting the save on a win keeps the settings

// What survives a restart. Selection, hover and undo history don't.
Save_Data :: struct {
	version:    int,
	difficulty: puzzle.Difficulty,
	seed:       u64,
	board:      puzzle.Board,
	elapsed:    f32,
	hints:      int,
}

save_game :: proc(play: Play) -> bool {
	data := Save_Data {
		version    = SAVE_VERSION,
		difficulty = play.difficulty,
		seed       = play.seed,
		board      = play.board,
		elapsed    = play.elapsed,
		hints      = play.hints,
	}
	bytes, err := json.marshal(
		data,
		{pretty = true, use_enum_names = true},
		context.temp_allocator,
	)
	if err != nil do return false
	return store_write(SAVE_NAME, bytes)
}

load_game :: proc() -> (data: Save_Data, ok: bool) {
	bytes := store_read(SAVE_NAME, context.temp_allocator) or_return
	if json.unmarshal(bytes, &data, allocator = context.temp_allocator) != nil do return
	if data.version != SAVE_VERSION do return
	return data, true
}

delete_save :: proc() {
	store_remove(SAVE_NAME)
}

save_settings :: proc(settings: Settings) -> bool {
	bytes, err := json.marshal(settings, {pretty = true}, context.temp_allocator)
	if err != nil do return false
	return store_write(SETTINGS_NAME, bytes)
}

load_settings :: proc() -> (settings: Settings) {
	bytes, ok := store_read(SETTINGS_NAME, context.temp_allocator)
	if !ok do return
	json.unmarshal(bytes, &settings, allocator = context.temp_allocator) // on error: defaults
	return
}

// Puzzle saved by save_game becomes the current one, ready for Continue
resume :: proc(game: ^Game, data: Save_Data) {
	delete(game.play.history)
	game.play = {}
	game.play.difficulty = data.difficulty
	game.play.seed = data.seed
	game.play.board = data.board
	game.play.elapsed = data.elapsed
	game.play.hints = data.hints
	game.in_progress = true
}
