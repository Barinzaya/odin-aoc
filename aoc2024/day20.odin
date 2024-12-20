package aoc2024

import ba "core:container/bit_array"
import "core:fmt"
import "core:math/linalg"
import "core:os"
import "core:strings"
import "core:testing"
import "core:time"

Day20_Input :: struct {
	walls: ba.Bit_Array,
	size: [2]int,
	start: [2]int,
	end: [2]int,
}

Day20_Input_Error :: enum {
	Ok,
	Invalid_Cell,
	No_Start,
	No_End,
	Multiple_Starts,
	Multiple_Ends,
	Ragged_Grid,
}

day20 :: proc (input: string) {
	t := time.tick_now()

	grid, err := day20_parse(input)
	defer ba.destroy(&grid.walls)
	if err != nil {
		fmt.eprintln("Failed to parse input", err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day20_solve(&grid, 2, 100)
	p1_dur := time.tick_lap_time(&t)

	p2 := day20_solve(&grid, 20, 100)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day20_parse :: proc (input: string) -> (result: Day20_Input, err: Day20_Input_Error) {
	result.size.x = strings.index_byte(input, '\n')
	result.size.y = (len(input) + 1) / (result.size.x + 1)

	walls : ba.Bit_Array
	ba.init(&walls, result.size.x * result.size.y)
	defer if err != nil do ba.destroy(&walls)

	x, y : int
	for b in transmute([]u8)input {
		switch b {
		case '#':
			i := x + y * result.size.x
			ba.set(&walls, i)
			x += 1

		case '.':
			x += 1

		case 'S':
			if result.start != ({}) do return {}, .Multiple_Starts
			result.start = {x, y}
			x += 1

		case 'E':
			if result.end != ({}) do return {}, .Multiple_Ends
			result.end = {x, y}
			x += 1

		case '\n':
			if x != result.size.x do return {}, .Ragged_Grid
			x = 0
			y += 1

		case: return {}, .Invalid_Cell
		}
	}

	if result.start == ({}) do return {}, .No_Start
	if result.end == ({}) do return {}, .No_End

	result.walls = walls
	return
}

day20_solve :: proc (input: ^Day20_Input, cheat_time, threshold: int) -> (result: int) {
	cost := make([]int, input.size.x * input.size.y)
	defer delete(cost)

	start_index := input.start.x + input.start.y * input.size.x
	cost[start_index] = 1

	last_cost := 1
	pos := input.start

	@(static, rodata)
	neighbors := [?][2]i8 {
		{ 0, -1},
		{+1,  0},
		{ 0, +1},
		{-1,  0},
	}

	for pos != input.end {
		for neighbor in neighbors {
			neighbor := pos + linalg.array_cast(neighbor, int)

			i := neighbor.x + neighbor.y * input.size.x
			if ba.unsafe_get(&input.walls, i) do continue
			if cost[i] > 0 do continue

			last_cost += 1
			cost[i] = last_cost
			pos = neighbor
			break
		}

		cheat_max := min(cheat_time, last_cost - 1)
		min_dy := max(-cheat_max, -pos.y)
		max_dy := min(+cheat_max, input.size.y - 1 - pos.y)

		for dy in min_dy..=max_dy {
			cheat_left := cheat_time - abs(dy)
			min_dx := max(-cheat_left, -pos.x)
			max_dx := min(+cheat_left, input.size.x - 1 - pos.x)

			for dx in min_dx..=max_dx {
				cheat_pos := pos + [2]int {dx, dy}

				i := cheat_pos.x + cheat_pos.y * input.size.x
				if ba.unsafe_get(&input.walls, i) do continue
				if cost[i] == 0 do continue

				saved := last_cost - cost[i] - abs(dx) - abs(dy)
				if saved >= threshold do result += 1
			}
		}
	}

	return
}

DAY20_EXAMPLE ::
`###############
#...#...#.....#
#.#.#.#.#.###.#
#S#...#.#.#...#
#######.#.#.###
#######.#.#...#
#######.#.###.#
###..E#...#...#
###.#######.###
#...###...#...#
#.#####.#.###.#
#.#...#.#.#...#
#.#.#.#.#.#.###
#...#...#...###
###############`

@test
day20_test :: proc (t: ^testing.T) {
	grid, err := day20_parse(DAY20_EXAMPLE)
	defer ba.destroy(&grid.walls)

	testing.expect_value(t, err, nil)
	testing.expect_value(t, grid.size, [2]int {15, 15})
	testing.expect_value(t, grid.start, [2]int {1, 3})
	testing.expect_value(t, grid.end, [2]int {5, 7})

	testing.expect_value(t, day20_solve(&grid, 2, 10), 10)
	testing.expect_value(t, day20_solve(&grid, 2, 12), 8)
	testing.expect_value(t, day20_solve(&grid, 2, 20), 5)
	testing.expect_value(t, day20_solve(&grid, 2, 36), 4)
	testing.expect_value(t, day20_solve(&grid, 2, 38), 3)
	testing.expect_value(t, day20_solve(&grid, 2, 40), 2)
	testing.expect_value(t, day20_solve(&grid, 2, 64), 1)

	testing.expect_value(t, day20_solve(&grid, 20, 70), 41)
	testing.expect_value(t, day20_solve(&grid, 20, 72), 29)
	testing.expect_value(t, day20_solve(&grid, 20, 74), 7)
	testing.expect_value(t, day20_solve(&grid, 20, 76), 3)
}

