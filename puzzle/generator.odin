package puzzle

import "core:math/rand"

Difficulty :: enum {
	Easy,
	Medium,
	Hard,
}

// Target number of given digits. A variable, not a constant (::): Odin can't
// index a constant array with a runtime value. Hard may end with a few more:
// removal stops when no digit can go without breaking uniqueness.
@(rodata)
CLUES := [Difficulty]int {
	.Easy   = 40,
	.Medium = 32,
	.Hard   = 26,
}

// Random puzzle with a unique solution. The same seed always gives the same puzzle.
generate :: proc(difficulty: Difficulty, seed: u64) -> (b: Board) {
	state := rand.create(seed)
	gen := rand.default_random_generator(&state)

	// 1. A random full grid: the diagonal boxes don't see each other, so they
	//    can be shuffled freely, then the solver completes the rest.
	fill_diagonal(&b.cells, gen)
	solve(&b.cells)

	// 2. Remove digits in random order, keeping only removals that leave one solution
	order: [81]int
	for i in 0 ..< 81 do order[i] = i
	rand.shuffle(order[:], gen)

	clues := 81
	for i in order {
		if clues <= CLUES[difficulty] do break
		r, c := i / 9, i % 9
		v := b.cells[r][c]
		b.cells[r][c] = 0
		if count_solutions(&b.cells, 2) == 1 {
			clues -= 1
		} else {
			b.cells[r][c] = v // this digit was needed
		}
	}

	for r in 0 ..< 9 {
		for c in 0 ..< 9 do b.given[r][c] = b.cells[r][c] != 0
	}
	return
}

// Number of given digits on the board
count_clues :: proc(b: Board) -> (n: int) {
	for r in 0 ..< 9 {
		for c in 0 ..< 9 do if b.given[r][c] do n += 1
	}
	return
}

@(private = "file")
fill_diagonal :: proc(cells: ^[9][9]u8, gen: rand.Generator) {
	digits := [9]u8{1, 2, 3, 4, 5, 6, 7, 8, 9}
	for box in 0 ..< 3 {
		rand.shuffle(digits[:], gen)
		for i in 0 ..< 9 {
			cells[box * 3 + i / 3][box * 3 + i % 3] = digits[i]
		}
	}
}
