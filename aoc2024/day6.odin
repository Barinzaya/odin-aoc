package aoc2024

import "core:fmt"
import "core:math/bits"
import "core:math/linalg"
import "core:os"
import "core:strings"
import "core:testing"
import "core:time"

Day6_Dir :: enum u8 { North, East, South, West }

@rodata
day6_dir_offsets := [Day6_Dir][2]i8 {
	.North = { 0, -1},
	.East  = {+1,  0},
	.South = { 0, +1},
	.West  = {-1,  0},
}

Day6_Grid :: struct {
	width, height: int,
	cells: []u64,

	guard_pos: [2]int,
}

Day6_Input_Error :: enum {
	Ok,
	Multiple_Guards,
	No_Guard,
	Ragged_Grid,
	Unknown_Cell,
}

day6 :: proc (input: string) {
	t := time.tick_now()

	grid, input_err := day6_parse(input)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}
	defer delete(grid.cells)
	parse_dur := time.tick_lap_time(&t)

	p1 := day6_part1(grid)
	p1_dur := time.tick_lap_time(&t)

	p2 := day6_part2(grid)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day6_parse :: proc (input: string) -> (grid: Day6_Grid, err: Day6_Input_Error) {
	cells := make([]u64, (len(input) + 63) / 64)
	defer if err != nil do delete(cells)

	grid.guard_pos = -1

	remainder := input
	y := 0
	for line in strings.split_lines_iterator(&remainder) {
		if grid.width != 0 && grid.width != len(line) do return {}, .Ragged_Grid
		defer y += 1

		grid.width = len(line)
		grid.height += 1

		for b, x in transmute([]u8)line {
			switch b {
			case '.': continue
			case '#': 
				i := y*grid.width + x
				cells[i/64] |= 1 << u64(i%64)

			case '^':
				if grid.guard_pos.x >= 0 do return {}, .Multiple_Guards
				grid.guard_pos = {x, y}

			case: return {}, .Ragged_Grid
			}
		}
	}

	if grid.guard_pos.x < 0 do return {}, .No_Guard

	grid.cells = cells
	return
}

day6_part1 :: proc (grid: Day6_Grid) -> (result: uint) {
	visited := make([]u64, len(grid.cells))
	defer delete(visited)

	guard_pos := grid.guard_pos
	guard_dir := Day6_Dir.North

	for {
		i := guard_pos.y*grid.width + guard_pos.x
		visited[i/64] |= 1 << uint(i%64)

		guard_pos, guard_dir = day6_step(grid, guard_pos, guard_dir) or_break
	}

	for v in visited do result += uint(bits.count_ones(v))
	return
}

day6_part2 :: proc (grid: Day6_Grid) -> (result: uint) #no_bounds_check {
	exits := make([]u64, 4 * len(grid.cells))
	defer delete(exits)

	temp := make([]u64, 4 * len(grid.cells))
	defer delete(temp)

	candidates := make([]u64, len(grid.cells))
	defer delete(candidates)

	guard_pos := grid.guard_pos
	guard_dir := Day6_Dir.North

	h := guard_pos.y*grid.width + guard_pos.x
	candidates[h/64] |= 1 << uint(h%64)

	for new_pos, new_dir in day6_step(grid, guard_pos, guard_dir) {
		i := guard_pos.y*grid.width + guard_pos.x
		exits[i/16] |= 1 << uint(i%16*4 + int(new_dir))

		i2 := new_pos.y*grid.width + new_pos.x
		cand_mask := u64(1 << uint(i2%64))

		if candidates[i2/64] & cand_mask == 0 {
			candidates[i2/64] |= cand_mask
			grid.cells[i2/64] |= cand_mask

			copy(temp, exits)
			sim_pos, sim_dir := guard_pos, Day6_Dir((u8(new_dir) + 1) % len(Day6_Dir))

			for new_sim_pos, new_sim_dir in day6_step(grid, sim_pos, sim_dir) {
				j := sim_pos.y*grid.width + sim_pos.x
				exit_mask := u64(1) << uint(j%16*4 + int(new_sim_dir))

				if temp[j/16] & exit_mask != 0 {
					result += 1
					break
				}

				temp[j/16] |= exit_mask
				sim_pos, sim_dir = new_sim_pos, new_sim_dir
			}

			grid.cells[i2/64] &~= cand_mask
		}

		guard_pos, guard_dir = new_pos, new_dir
	}

	return
}

day6_step :: proc (grid: Day6_Grid, pos: [2]int, dir: Day6_Dir) -> (new_pos: [2]int, new_dir: Day6_Dir, ok: bool) {
	new_dir = dir
	for {
		new_pos = pos + linalg.array_cast(day6_dir_offsets[new_dir], int)
		if new_pos.x < 0 || new_pos.x >= grid.width || new_pos.y < 0 || new_pos.y >= grid.height {
			return
		}

		i := new_pos.y*grid.width + new_pos.x
		if grid.cells[i/64] & (1 << uint(i%64)) == 0 {
			ok = true
			return
		}

		new_dir = Day6_Dir((u8(new_dir) + 1) % len(Day6_Dir))
		if dir == new_dir {
			new_pos = pos
			return
		}
	}
}

DAY6_EXAMPLE ::
`....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...`

@test
test_day6 :: proc (t: ^testing.T) {
	grid, input_err := day6_parse(DAY6_EXAMPLE)
	testing.expect_value(t, input_err, nil)
	defer delete(grid.cells)

	testing.expect_value(t, grid.width, 10)
	testing.expect_value(t, grid.height, 10)
	testing.expect_value(t, grid.guard_pos, [2]int { 4, 6 })

	p1 := day6_part1(grid)
	testing.expect_value(t, p1, 41)

	p2 := day6_part2(grid)
	testing.expect_value(t, p2, 6)
}
