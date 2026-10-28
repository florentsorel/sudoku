package puzzle

import "core:testing"

// Row 0 forces a 9 in its last cell, but column 8 already has one: no solution,
// even though no two digits clash yet.
UNSOLVABLE :: "12345678.........9"

@(test)
test_solve_sample :: proc(t: ^testing.T) {
	b, expected: Board
	load(&b, SAMPLE)
	load(&expected, SOLUTION)

	testing.expect(t, solve(&b.cells))
	testing.expect(t, b.cells == expected.cells)
}

@(test)
test_solve_already_solved :: proc(t: ^testing.T) {
	b: Board
	load(&b, SOLUTION)
	before := b.cells

	testing.expect(t, solve(&b.cells))
	testing.expect(t, b.cells == before) // nothing to fill, nothing changed
}

@(test)
test_solve_unsolvable :: proc(t: ^testing.T) {
	b: Board
	load(&b, UNSOLVABLE)
	before := b.cells

	testing.expect(t, !solve(&b.cells))
	testing.expect(t, b.cells == before) // every attempt was undone
}

@(test)
test_count_solutions_unique :: proc(t: ^testing.T) {
	b: Board
	load(&b, SAMPLE)
	testing.expect_value(t, count_solutions(&b.cells, 2), 1)
}

@(test)
test_count_solutions_stops_at_limit :: proc(t: ^testing.T) {
	b: Board // empty grid: billions of solutions, must stop at the limit
	testing.expect_value(t, count_solutions(&b.cells, 2), 2)
}

@(test)
test_count_solutions_none :: proc(t: ^testing.T) {
	b: Board
	load(&b, UNSOLVABLE)
	testing.expect_value(t, count_solutions(&b.cells, 2), 0)
}

@(test)
test_count_solutions_leaves_grid_untouched :: proc(t: ^testing.T) {
	b: Board
	load(&b, SAMPLE)
	before := b.cells

	count_solutions(&b.cells, 2)
	testing.expect(t, b.cells == before) // counting must undo every digit it tried
}
