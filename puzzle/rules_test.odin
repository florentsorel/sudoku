package puzzle

import "core:testing"

SAMPLE :: "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79"

SOLUTION :: "534678912672195348198342567859761423426853791713924856961537284287419635345286179"

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

@(test)
test_is_solved :: proc(t: ^testing.T) {
	b: Board

	load(&b, SAMPLE)
	testing.expect(t, !is_solved(&b.cells))

	load(&b, SOLUTION)
	testing.expect(t, is_solved(&b.cells))

	b.cells[0][0], b.cells[0][1] = b.cells[0][1], b.cells[0][0]
	testing.expect(t, !is_solved(&b.cells))
}

@(test)
test_unit_cells :: proc(t: ^testing.T) {
	testing.expect_value(t, unit_cells(2)[5], [2]int{2, 5}) // row 2
	testing.expect_value(t, unit_cells(9 + 4)[7], [2]int{7, 4}) // column 4
	testing.expect_value(t, unit_cells(18 + 4)[0], [2]int{3, 3}) // center box
	testing.expect_value(t, unit_cells(18 + 8)[8], [2]int{8, 8}) // last box
}

@(test)
test_is_unit_complete :: proc(t: ^testing.T) {
	b: Board
	load(&b, SOLUTION)
	for unit in 0 ..< UNIT_COUNT do testing.expect(t, is_unit_complete(&b.cells, unit))

	b.cells[0][0] = 0
	testing.expect(t, !is_unit_complete(&b.cells, 0)) // row 0 has a hole
	testing.expect(t, is_unit_complete(&b.cells, 1)) // row 1 untouched

	b.cells[0][0] = 3 // duplicate of the 3 at (0, 1)
	testing.expect(t, !is_unit_complete(&b.cells, 0))
}
