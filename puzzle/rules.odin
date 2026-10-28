package puzzle

is_valid :: proc(cells: ^[9][9]u8, row, col: int, n: u8) -> bool {
	for i in 0 ..< 9 {
		if i != col && cells[row][i] == n do return false
		if i != row && cells[i][col] == n do return false
	}

	br, bc := (row / 3) * 3, (col / 3) * 3
	for r in br ..< br + 3 {
		for c in bc ..< bc + 3 {
			if (r != row || c != col) && cells[r][c] == n do return false
		}
	}

	return true
}
