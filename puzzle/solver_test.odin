#+build !js
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

@(test)
test_solution_ignores_player_digits :: proc(t: ^testing.T) {
	b, expected: Board
	load(&b, SAMPLE)
	load(&expected, SOLUTION)
	set(&b, 0, 2, 5) // wrong player digit, clashes with the 5 in row 0

	cells, ok := solution(b)
	testing.expect(t, ok)
	testing.expect(t, cells == expected.cells)
	testing.expect_value(t, b.cells[0][2], 5) // the board itself is untouched
}

@(test)
test_solution_unsolvable :: proc(t: ^testing.T) {
	b: Board
	load(&b, UNSOLVABLE)

	_, ok := solution(b)
	testing.expect(t, !ok)
}

@(test)
test_hint_fills_empty_cell :: proc(t: ^testing.T) {
	b: Board
	load(&b, SAMPLE)

	testing.expect(t, hint(&b, 0, 2))
	testing.expect_value(t, b.cells[0][2], 4) // SOLUTION row 0: 534678912
}

@(test)
test_hint_fixes_wrong_digit :: proc(t: ^testing.T) {
	b: Board
	load(&b, SAMPLE)
	set(&b, 0, 2, 9) // wrong guess

	testing.expect(t, hint(&b, 0, 2))
	testing.expect_value(t, b.cells[0][2], 4)
}

@(test)
test_hint_refuses_given_cell :: proc(t: ^testing.T) {
	b: Board
	load(&b, SAMPLE)

	testing.expect(t, !hint(&b, 0, 0))
	testing.expect_value(t, b.cells[0][0], 5)
}

@(test)
test_candidates :: proc(t: ^testing.T) {
	b: Board
	load(&b, SAMPLE)
	// (0, 2): row has 5 3 7, column has 8, box has 6 9 8 → 1 2 4 left
	testing.expect_value(t, candidates(&b.cells, 0, 2), Digits{1, 2, 4})
}
