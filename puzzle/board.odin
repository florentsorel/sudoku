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

// Write v (0 = clear) into (r, c). Given cells are never modified.
set :: proc(b: ^Board, r, c: int, v: u8) -> bool {
	if b.given[r][c] do return false
	b.cells[r][c] = v
	return true
}

// Two cells share a 3×3 box when their box coordinates match
same_box :: proc(a, b: [2]int) -> bool {
	return a / 3 == b / 3
}

// Peers can't hold the same digit: same row, column or box
is_peer :: proc(a, b: [2]int) -> bool {
	return a != b && (a[0] == b[0] || a[1] == b[1] || same_box(a, b))
}
