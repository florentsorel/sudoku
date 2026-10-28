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

// First empty cell, scanning row by row. ok = false if the grid is full.
@(private = "file")
find_empty :: proc(cells: ^[9][9]u8) -> (int, int, bool) {
	for row in 0 ..< 9 {
		for col in 0 ..< 9 {
			if cells[row][col] == 0 do return row, col, true
		}
	}
	return 0, 0, false // grid is full
}
