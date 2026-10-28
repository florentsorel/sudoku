package main

import "core:encoding/json"
import "core:os"
import "puzzle"

// Bump when Save_Data changes shape: older saves are then ignored, not misread
SAVE_VERSION :: 1

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
	dir, path, ok := save_location()
	if !ok do return false
	if os.make_directory_all(dir) != nil && !os.exists(dir) do return false

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
	return os.write_entire_file(path, bytes) == nil
}

load_game :: proc() -> (data: Save_Data, ok: bool) {
	_, path := save_location() or_return
	bytes, err := os.read_entire_file(path, context.temp_allocator)
	if err != nil do return
	if json.unmarshal(bytes, &data, allocator = context.temp_allocator) != nil do return
	if data.version != SAVE_VERSION do return
	return data, true
}

delete_save :: proc() {
	if _, path, ok := save_location(); ok do os.remove(path)
}

// Settings live in their own file: deleting the save on a win must not reset them
save_settings :: proc(settings: Settings) -> bool {
	dir, path, ok := save_location("settings.json")
	if !ok do return false
	if os.make_directory_all(dir) != nil && !os.exists(dir) do return false
	bytes, err := json.marshal(settings, {pretty = true}, context.temp_allocator)
	if err != nil do return false
	return os.write_entire_file(path, bytes) == nil
}

load_settings :: proc() -> (settings: Settings) {
	_, path, ok := save_location("settings.json")
	if !ok do return
	bytes, err := os.read_entire_file(path, context.temp_allocator)
	if err != nil do return
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

// ~/Library/Application Support/sudoku-odin/save.json on macOS. Temp allocated.
@(private = "file")
save_location :: proc(file := "save.json") -> (dir, path: string, ok: bool) {
	base, err := os.user_data_dir(context.temp_allocator)
	if err != nil do return
	dir, _ = os.join_path({base, "sudoku-odin"}, context.temp_allocator)
	path, _ = os.join_path({dir, file}, context.temp_allocator)
	return dir, path, true
}
