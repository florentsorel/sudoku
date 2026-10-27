package puzzle


Board :: struct {
	cells: [9][9]u8,
	given: [9][9]bool,
}

load :: proc(b: ^Board, s: string) {
	idx := 0
	for ch in s {
		r, c := idx / 9, idx % 9
		switch ch {
		case '1' ..= '9':
			b.cells[r][c] = u8(ch - '0')
			b.given[r][c] = true
			idx += 1
		case '0', '.':
			b.cells[r][c] = 0
			b.given[r][c] = false
			idx += 1
		case:
			continue
		}

		if idx == 81 do break
	}
}
