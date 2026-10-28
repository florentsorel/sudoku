package puzzle

// A set of digits 1-9, one bit each: pencil notes, candidates
Digits :: bit_set[1 ..= 9]

Board :: struct {
	cells: [9][9]u8,
	given: [9][9]bool,
	notes: [9][9]Digits, // pencil marks, only meaningful on empty cells
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
// Placing a digit wipes the cell's notes and that digit from its peers' notes.
set :: proc(b: ^Board, r, c: int, v: u8) -> bool {
	if b.given[r][c] do return false
	b.cells[r][c] = v
	if v != 0 {
		b.notes[r][c] = {}
		for pr in 0 ..< 9 {
			for pc in 0 ..< 9 {
				if is_peer({r, c}, {pr, pc}) do b.notes[pr][pc] -= {int(v)}
			}
		}
	}
	return true
}

// Add or remove pencil note n in (r, c). Only on empty, non-given cells.
toggle_note :: proc(b: ^Board, r, c: int, n: u8) -> bool {
	if b.given[r][c] || b.cells[r][c] != 0 do return false
	b.notes[r][c] ~= {int(n)} // ~ on a bit_set: symmetric difference, flips n
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
