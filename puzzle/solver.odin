package puzzle

solve :: proc(cells: ^[9][9]u8) -> bool {
	r, c, ok := find_empty(cells)
	if !ok do return true

	for n in u8(1) ..= 9 {
		if is_valid(cells, r, c, n) {
			cells[r][c] = n
			if solve(cells) do return true
			cells[r][c] = 0
		}
	}

	return false
}

count_solutions :: proc(cells: ^[9][9]u8, limit: int) -> int {
	r, c, ok := find_empty(cells)
	if !ok do return 1

	total := 0
	for n in u8(1) ..= 9 {
		if is_valid(cells, r, c, n) {
			cells[r][c] = n
			total += count_solutions(cells, limit - total)
			cells[r][c] = 0

			if total >= limit do return total
		}
	}

	return total
}

// Solution of the board from its given digits only, ignoring the player's entries
solution :: proc(b: Board) -> (cells: [9][9]u8, ok: bool) {
	for r in 0 ..< 9 {
		for c in 0 ..< 9 {
			if b.given[r][c] do cells[r][c] = b.cells[r][c]
		}
	}
	ok = solve(&cells)
	return
}

// Reveal the right digit in (r, c). Fails on given cells or an unsolvable board.
hint :: proc(b: ^Board, r, c: int) -> bool {
	cells, ok := solution(b^)
	if !ok do return false
	return set(b, r, c, cells[r][c])
}

// Empty cell with the fewest candidates, ok = false if the grid is full.
// Trying the most constrained cell first makes the search tree much smaller.
@(private = "file")
find_empty :: proc(cells: ^[9][9]u8) -> (int, int, bool) {
	best_r, best_c, best_n := 0, 0, 10
	for row in 0 ..< 9 {
		for col in 0 ..< 9 {
			if cells[row][col] != 0 do continue
			n := card(candidates(cells, row, col))
			if n < best_n {
				best_r, best_c, best_n = row, col, n
				if n <= 1 do return row, col, true // can't do better
			}
		}
	}
	return best_r, best_c, best_n < 10
}

// Digits that can still go in (r, c) given its row, column and box
candidates :: proc(cells: ^[9][9]u8, r, c: int) -> (free: Digits) {
	used: bit_set[0 ..= 9] // 0 included so empty cells can be added without a check
	br, bc := r / 3 * 3, c / 3 * 3
	for i in 0 ..< 9 {
		used += {int(cells[r][i]), int(cells[i][c]), int(cells[br + i / 3][bc + i % 3])}
	}
	for n in 1 ..= 9 do if n not_in used do free += {n}
	return
}
