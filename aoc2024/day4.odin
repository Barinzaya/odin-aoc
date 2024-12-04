package aoc2024

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"
import "core:time"

Day4_Input :: struct {
	w, h: int,
	cells: []u8,
}

Day4_Input_Error :: enum {
	Ragged_Lines,
}

day4 :: proc (input: string) {
	t := time.tick_now()

	w, h, input_err := day4_parse(input)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}

	parse_dur := time.tick_lap_time(&t)

	p1 := day4_part1(input, w, h)
	p1_dur := time.tick_lap_time(&t)

	p2 := day4_part2(input, w, h)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day4_parse :: proc (input: string) -> (w, h: int, err: Day4_Input_Error) {
	left := input
	for line in strings.split_lines_iterator(&left) {
		if w == 0 || w == len(line) {
			w = len(line)
		} else {
			return 0, 0, .Ragged_Lines
		}

		h += 1
	}
	return
}

day4_part1 :: proc (input: string, w, h: int) -> (result: int) {
	check :: proc (input: string, w, h, x, y: int) -> (count: int) {
		@(static, rodata)
		directions := [?][2]i8 {
			{+1,  0},
			{ 0, +1},
			{-1,  0},
			{ 0, -1},
			{+1, +1},
			{-1, +1},
			{-1, -1},
			{+1, -1},
		}

		@(static, rodata)
		chars := [?]u8 { 'M', 'A', 'S' }

		outer: for direction in directions {
			for b, i in chars {
				x2 := x + int(direction.x) * (i + 1)
				if x2 < 0 || x2 >= w do continue outer

				y2 := y + int(direction.y) * (i + 1)
				if y2 < 0 || y2 >= h do continue outer

				j := y2 * (w + 1) + x2
				if input[j] != b do continue outer
			}

			count += 1
		}

		return
	}

	for y in 0..<h {
		for x in 0..<w {
			i := y * (w + 1) + x
			if input[i] == 'X' {
				result += check(input, w, h, x, y)
			}
		}
	}

	return
}

day4_part2 :: proc (input: string, w, h: int) -> (result: int) {
	for y in 1..<(h-1) {
		for x in 1..<(w-1) {
			i := y * (w + 1) + x
			if input[i] != 'A' do continue

			ul := input[i - w - 2]
			br := input[i + w + 2]
			if min(ul, br) != 'M' || max(ul, br) != 'S' do continue

			ur := input[i - w - 0]
			bl := input[i + w + 0]
			if min(ur, bl) != 'M' || max(ur, bl) != 'S' do continue

			result += 1
		}
	}

	return
}

DAY4_PART1_EXAMPLE ::
`MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX`

@test
test_day4_part1 :: proc (t: ^testing.T) {
	w, h, err := day4_parse(DAY4_PART1_EXAMPLE)
	testing.expect_value(t, err, nil)

	p1 := day4_part1(DAY4_PART1_EXAMPLE, w, h)
	testing.expect_value(t, p1, 18)
}

DAY4_PART2_EXAMPLE ::
`.M.S......
..A..MSMS.
.M.S.MAA..
..A.ASMSM.
.M.S.M....
..........
S.S.S.S.S.
.A.A.A.A..
M.M.M.M.M.
..........`

@test
test_day4_part2 :: proc (t: ^testing.T) {
	w, h, err := day4_parse(DAY4_PART2_EXAMPLE)
	testing.expect_value(t, err, nil)

	p2 := day4_part2(DAY4_PART2_EXAMPLE, w, h)
	testing.expect_value(t, p2, 9)
}
