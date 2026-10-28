package main

import "core:testing"
import "puzzle"

@(test)
test_record_and_undo :: proc(t: ^testing.T) {
	play: Play
	defer delete(play.history)
	puzzle.load(
		&play.board,
		"53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79",
	)
	start := play.board

	before := play.board
	puzzle.set(&play.board, 0, 2, 4)
	testing.expect(t, record(&play, before))

	before = play.board
	puzzle.toggle_note(&play.board, 0, 3, 6)
	testing.expect(t, record(&play, before))

	testing.expect(t, undo(&play))
	testing.expect(t, 6 not_in play.board.notes[0][3])
	testing.expect_value(t, play.board.cells[0][2], 4) // first edit still there

	testing.expect(t, undo(&play))
	testing.expect(t, play.board == start)
	testing.expect(t, !undo(&play)) // nothing left
}

@(test)
test_record_ignores_no_op :: proc(t: ^testing.T) {
	play: Play
	defer delete(play.history)
	puzzle.load(
		&play.board,
		"53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79",
	)

	before := play.board
	puzzle.set(&play.board, 0, 0, 9) // given cell: refused, nothing changes
	testing.expect(t, !record(&play, before))
	testing.expect_value(t, len(play.history), 0)
}
