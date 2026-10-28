#+build !js
package puzzle

import "core:testing"

@(test)
test_generate_unique_solution :: proc(t: ^testing.T) {
	for difficulty in Difficulty {
		b := generate(difficulty, 42)
		testing.expectf(t, count_solutions(&b.cells, 2) == 1, "%v: not unique", difficulty)
	}
}

@(test)
test_generate_clue_count :: proc(t: ^testing.T) {
	for difficulty in Difficulty {
		b := generate(difficulty, 7)
		n := count_clues(b)
		// Never fewer than the target; Hard may keep a few more
		testing.expectf(t, n >= CLUES[difficulty], "%v: %d clues", difficulty, n)
		testing.expectf(t, n <= CLUES[difficulty] + 6, "%v: %d clues", difficulty, n)
	}
	testing.expect_value(t, count_clues(generate(.Easy, 7)), CLUES[.Easy])
}

@(test)
test_generate_given_matches_cells :: proc(t: ^testing.T) {
	b := generate(.Medium, 3)
	for r in 0 ..< 9 {
		for c in 0 ..< 9 {
			testing.expect(t, b.given[r][c] == (b.cells[r][c] != 0))
			if b.cells[r][c] != 0 do testing.expect(t, is_valid(&b.cells, r, c, b.cells[r][c]))
		}
	}
}

@(test)
test_generate_same_seed_same_puzzle :: proc(t: ^testing.T) {
	testing.expect(t, generate(.Medium, 1234) == generate(.Medium, 1234))
	testing.expect(t, generate(.Medium, 1234) != generate(.Medium, 1235))
}
