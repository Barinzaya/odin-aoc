package aoc2024

import "core:fmt"
import "core:math/bits"
import "core:os"
import "core:slice"
import "core:testing"
import "core:time"

Day8_Input :: struct {
	w, h: u16,
	frequencies: [128][dynamic][2]u16,
}

Day8_Input_Error :: enum {
	Ok,
	Invalid_Frequency,
	Ragged,
}

day8 :: proc (input: string) {
	t := time.tick_now()

	grid : Day8_Input
	if input_err := day8_parse(input, &grid); input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day8_part1(grid)
	p1_dur := time.tick_lap_time(&t)

	p2 := day8_part2(grid)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day8_parse :: proc (input: string, result: ^Day8_Input) -> (error: Day8_Input_Error) {
	defer if error != nil {
		for &v in result.frequencies {
			delete(v)
			v = {}
		}
	}

	x, y : u16
	for b in transmute([]u8)input {
		result.h = y+1

		switch b {
		case '\n':
			if y == 0 {
				result.w = x
			} else if x != result.w {
				return .Ragged
			}

			x = 0
			y += 1
			continue

		case '.':
			x += 1
			continue
		}

		append(&result.frequencies[b], [2]u16 {x, y})
		x += 1
	}

	return
}

day8_part1 :: proc (grid: Day8_Input) -> (result: u64) {
	antinodes := make([]u64, (grid.w*grid.h + 63) / 64)
	defer delete(antinodes)

	for locations in grid.frequencies {
		for a, i in locations {
			for b in locations[i+1:] {
				d := b - a

				anti := b + d
				if anti.x < grid.w && anti.y < grid.h {
					j := anti.y*grid.w + anti.x
					antinodes[j/64] |= 1 << (j % 64)
				}

				anti = a - d
				if anti.x < grid.w && anti.y < grid.h {
					j := anti.y*grid.w + anti.x
					antinodes[j/64] |= 1 << (j % 64)
				}
			}
		}
	}

	for word in antinodes do result += bits.count_ones(word)
	return
}

day8_part2 :: proc (grid: Day8_Input) -> (result: u64) {
	antinodes := make([]u64, (grid.w*grid.h + 63) / 64)
	defer delete(antinodes)

	for locations in grid.frequencies {
		for a, i in locations {
			for b in locations[i+1:] {
				d := b - a

				for anti := b; anti.x < grid.w && anti.y < grid.h; anti += d {
					j := anti.y*grid.w + anti.x
					antinodes[j/64] |= 1 << (j % 64)
				}

				for anti := a; anti.x < grid.w && anti.y < grid.h; anti -= d {
					j := anti.y*grid.w + anti.x
					antinodes[j/64] |= 1 << (j % 64)
				}
			}
		}
	}

	for word in antinodes do result += bits.count_ones(word)
	return
}

DAY8_EXAMPLE ::
`............
........0...
.....0......
.......0....
....0.......
......A.....
............
............
........A...
.........A..
............
............`

@test
test_day8 :: proc (t: ^testing.T) {
	grid : Day8_Input
	input_err := day8_parse(DAY8_EXAMPLE, &grid)
	defer for v in grid.frequencies do delete(v)

	testing.expect_value(t, input_err, nil)
	testing.expect_value(t, grid.w, 12)
	testing.expect_value(t, grid.h, 12)

	a_pos := grid.frequencies['A']
	testing.expect_value(t, len(a_pos), 3)
	testing.expect(t, slice.contains(a_pos[:], [2]u16 {6, 5}))
	testing.expect(t, slice.contains(a_pos[:], [2]u16 {8, 8}))
	testing.expect(t, slice.contains(a_pos[:], [2]u16 {9, 9}))

	z_pos := grid.frequencies['0']
	testing.expect_value(t, len(z_pos), 4)
	testing.expect(t, slice.contains(z_pos[:], [2]u16 {8, 1}))
	testing.expect(t, slice.contains(z_pos[:], [2]u16 {5, 2}))
	testing.expect(t, slice.contains(z_pos[:], [2]u16 {7, 3}))
	testing.expect(t, slice.contains(z_pos[:], [2]u16 {4, 4}))

	p1 := day8_part1(grid)
	testing.expect_value(t, p1, 14)

	p2 := day8_part2(grid)
	testing.expect_value(t, p2, 34)
}

