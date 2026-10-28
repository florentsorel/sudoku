#+build !js
package main

import "core:encoding/json"
import "core:testing"
import "puzzle"

// The JSON round trip keeps everything, notes (bit_set) and enum included
@(test)
test_save_data_round_trip :: proc(t: ^testing.T) {
	original := Save_Data {
		version    = SAVE_VERSION,
		difficulty = .Hard,
		seed       = 1234,
		board      = puzzle.generate(.Hard, 1234),
		elapsed    = 95.5,
		hints      = 2,
	}
	// A note on the first empty cell of column 4
	for r in 0 ..< 9 do if puzzle.toggle_note(&original.board, r, 4, 7) do break

	bytes, err := json.marshal(original, {use_enum_names = true}, context.temp_allocator)
	testing.expect(t, err == nil)

	loaded: Save_Data
	testing.expect(t, json.unmarshal(bytes, &loaded, allocator = context.temp_allocator) == nil)
	testing.expect(t, loaded == original)
}

@(test)
test_settings_round_trip :: proc(t: ^testing.T) {
	original := Settings {
		hide_highlights = true,
	}
	bytes, err := json.marshal(original, {}, context.temp_allocator)
	testing.expect(t, err == nil)

	loaded: Settings
	testing.expect(t, json.unmarshal(bytes, &loaded, allocator = context.temp_allocator) == nil)
	testing.expect(t, loaded == original)

	defaults: Settings // no file: highlights stay on
	testing.expect(t, !defaults.hide_highlights)
}
