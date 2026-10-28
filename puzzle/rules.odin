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

is_solved :: proc(cells: ^[9][9]u8) -> bool {
	for r in 0 ..< 9 {
		for c in 0 ..< 9 {
			v := cells[r][c]
			if v == 0 do return false
			if !is_valid(cells, r, c, v) do return false
		}
	}
	return true
}

// The 27 units of the grid: 9 rows, 9 columns, 9 boxes
UNIT_COUNT :: 27

// Cells of a unit: 0-8 rows, 9-17 columns, 18-26 boxes
unit_cells :: proc(unit: int) -> (cells: [9][2]int) {
	for i in 0 ..< 9 {
		switch unit / 9 {
		case 0:
			cells[i] = {unit, i}
		case 1:
			cells[i] = {i, unit - 9}
		case:
			b := unit - 18
			cells[i] = {b / 3 * 3 + i / 3, b % 3 * 3 + i % 3}
		}
	}
	return
}

// Every cell filled and no digit repeated
is_unit_complete :: proc(cells: ^[9][9]u8, unit: int) -> bool {
	seen: Digits
	for cell in unit_cells(unit) {
		v := cells[cell[0]][cell[1]]
		if v == 0 || int(v) in seen do return false
		seen += {int(v)}
	}
	return true
}
