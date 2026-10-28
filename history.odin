package main

import "puzzle"

// Undo keeps whole boards rather than individual moves: a single digit can also
// wipe notes in 20 peer cells, and a board is only ~330 bytes.

// Keep the board as it was before an edit, if the edit changed anything
record :: proc(play: ^Play, before: puzzle.Board) -> bool {
	if play.board == before do return false
	append(&play.history, before)
	return true
}

// Go back one edit. false when there is nothing to undo.
undo :: proc(play: ^Play) -> bool {
	if len(play.history) == 0 do return false
	play.board = pop(&play.history)
	return true
}
