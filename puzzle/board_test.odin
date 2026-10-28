#+build !js
package puzzle

import "core:testing"

@(test)
test_load_flat :: proc(t: ^testing.T) {
	b: Board
	load(&b, "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79")

	testing.expect_value(t, b.cells[0][0], 5)
	testing.expect_value(t, b.cells[0][2], 0)
	testing.expect(t, b.given[0][0])
	testing.expect(t, !b.given[0][2])
	testing.expect_value(t, b.cells[8][8], 9)
}

@(test)
test_load_ignores_layout :: proc(t: ^testing.T) {
	flat, pretty: Board
	load(
		&flat,
		"53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79",
	)
	load(
		&pretty,
		`
53. .7. ...
6.. 195 ...
.98 ... .6.
8.. .6. ..3
4.. 8.3 ..1
7.. .2. ..6
.6. ... 28.
... 419 ..5
... .8. .79
`,
	)
	testing.expect(t, flat == pretty)
}

@(test)
test_same_box :: proc(t: ^testing.T) {
	testing.expect(t, same_box({0, 0}, {2, 2})) // same top-left box
	testing.expect(t, same_box({4, 4}, {3, 5})) // same center box
	testing.expect(t, !same_box({2, 2}, {3, 3})) // diagonal neighbours, different boxes
	testing.expect(t, !same_box({0, 0}, {0, 3})) // same row, different boxes
}

@(test)
test_is_peer :: proc(t: ^testing.T) {
	testing.expect(t, is_peer({4, 4}, {4, 0})) // same row
	testing.expect(t, is_peer({4, 4}, {8, 4})) // same column
	testing.expect(t, is_peer({4, 4}, {3, 5})) // same box only
	testing.expect(t, !is_peer({4, 4}, {4, 4})) // a cell is not its own peer
	testing.expect(t, !is_peer({0, 0}, {4, 4})) // unrelated
}

@(test)
test_set :: proc(t: ^testing.T) {
	b: Board
	load(&b, "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79")

	// Empty cell: write then clear
	testing.expect(t, set(&b, 0, 2, 4))
	testing.expect_value(t, b.cells[0][2], 4)
	testing.expect(t, set(&b, 0, 2, 0))
	testing.expect_value(t, b.cells[0][2], 0)

	// Given cell: refused, value unchanged
	testing.expect(t, !set(&b, 0, 0, 9))
	testing.expect_value(t, b.cells[0][0], 5)
	testing.expect(t, !set(&b, 0, 0, 0))
	testing.expect_value(t, b.cells[0][0], 5)
}

@(test)
test_toggle_note :: proc(t: ^testing.T) {
	b: Board
	load(&b, SAMPLE)

	testing.expect(t, toggle_note(&b, 0, 2, 4))
	testing.expect(t, 4 in b.notes[0][2])
	testing.expect(t, toggle_note(&b, 0, 2, 4))
	testing.expect(t, 4 not_in b.notes[0][2]) // toggled back off

	testing.expect(t, !toggle_note(&b, 0, 0, 4)) // given cell
	set(&b, 0, 2, 1)
	testing.expect(t, !toggle_note(&b, 0, 2, 4)) // filled cell
}

@(test)
test_set_clears_notes :: proc(t: ^testing.T) {
	b: Board
	load(&b, SAMPLE)
	toggle_note(&b, 0, 2, 4)
	toggle_note(&b, 0, 2, 1)
	toggle_note(&b, 0, 3, 4) // same row
	toggle_note(&b, 8, 2, 4) // same column
	toggle_note(&b, 1, 1, 4) // same box
	toggle_note(&b, 4, 4, 4) // unrelated

	set(&b, 0, 2, 4)
	testing.expect_value(t, b.notes[0][2], Digits{}) // own notes wiped
	testing.expect(t, 4 not_in b.notes[0][3])
	testing.expect(t, 4 not_in b.notes[8][2])
	testing.expect(t, 4 not_in b.notes[1][1])
	testing.expect(t, 4 in b.notes[4][4]) // not a peer: kept
}
