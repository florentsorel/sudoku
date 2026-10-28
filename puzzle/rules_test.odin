package puzzle

import "core:testing"

SAMPLE :: "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79"

@(test)
test_is_valid :: proc(t: ^testing.T) {
	b: Board
	load(&b, SAMPLE)

	testing.expect(t, !is_valid(&b.cells, 0, 2, 5)) // 5 already in row 0
	testing.expect(t, !is_valid(&b.cells, 0, 2, 8)) // 8 already in column 2
	testing.expect(t, !is_valid(&b.cells, 0, 2, 9)) // 9 already in the top-left box
	testing.expect(t, is_valid(&b.cells, 0, 2, 1)) // 1 is free everywhere
	testing.expect(t, is_valid(&b.cells, 0, 0, 5)) // the 5 at (0, 0) doesn't clash with itself
}
