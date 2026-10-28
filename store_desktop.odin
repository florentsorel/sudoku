#+build !js
package main

import "core:os"

// Files in ~/Library/Application Support/sudoku-odin on macOS,
// %LOCALAPPDATA%\sudoku-odin on Windows, ~/.local/share/sudoku-odin on Linux.

store_write :: proc(name: string, data: []byte) -> bool {
	dir, path, ok := store_location(name)
	if !ok do return false
	if os.make_directory_all(dir) != nil && !os.exists(dir) do return false
	return os.write_entire_file(path, data) == nil
}

store_read :: proc(name: string, allocator := context.allocator) -> (data: []byte, ok: bool) {
	_, path := store_location(name) or_return
	bytes, err := os.read_entire_file(path, allocator)
	return bytes, err == nil
}

store_remove :: proc(name: string) {
	if _, path, ok := store_location(name); ok do os.remove(path)
}

// Temp allocated
@(private = "file")
store_location :: proc(name: string) -> (dir, path: string, ok: bool) {
	base, err := os.user_data_dir(context.temp_allocator)
	if err != nil do return
	dir, _ = os.join_path({base, "sudoku-odin"}, context.temp_allocator)
	path, _ = os.join_path({dir, name}, context.temp_allocator)
	return dir, path, true
}
