package puzzle

import "core:testing"

@(test)
test_load_flat :: proc(t: ^testing.T) {
	b: Board
	load(&b, "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79")

	testing.expect_value(t, b.cells[0][0], 5)
	testing.expect_value(t, b.cells[0][2], 0)
	testing.expect(t, b.given[0][0])
	testing.expect(t, !b.given[0][2])
	testing.expect_value(t, b.cells[8][8], 9)
}

@(test)
test_load_ignores_layout :: proc(t: ^testing.T) {
	flat, pretty: Board
	load(
		&flat,
		"53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79",
	)
	load(
		&pretty,
		`
53. .7. ...
6.. 195 ...
.98 ... .6.
8.. .6. ..3
4.. 8.3 ..1
7.. .2. ..6
.6. ... 28.
... 419 ..5
... .8. .79
`,
	)
	testing.expect(t, flat == pretty)
}
