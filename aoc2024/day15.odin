package aoc2024

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:testing"
import "core:time"

Day15_Cell :: enum u8 {
	Empty,
	Box,
	Wall,
}

Day15_Wide_Cell :: enum u8 {
	Empty,
	Box_Left,
	Box_Right,
	Wall,
}

Day15_Instruction :: enum u8 { N, E, S, W }

Day15_Input :: struct {
	size, robot_pos: [2]u16,
	cells: []Day15_Cell,
	instructions: []Day15_Instruction,
}

Day15_Input_Error :: enum {
	None,
	Ragged_Grid,
	Wide_Grid,
	Tall_Grid,
	Invalid_Cell,
	No_Robot,
	Multiple_Robots,
	Invalid_Instruction,
}

day15 :: proc (input: string) {
	t := time.tick_now()

	input, input_err := day15_parse(input)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day15_part1(input)
	p1_dur := time.tick_lap_time(&t)

	p2 := day15_part2(input)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day15_parse :: proc (input: string) -> (result: Day15_Input, err:Day15_Input_Error) {
	cells : [dynamic]Day15_Cell
	defer if result.cells == nil do delete(cells)

	NO_ROBOT :: [2]u16 { max(u16), max(u16) }

	w, h : u16
	robot_pos := NO_ROBOT

	i, x, y : int
	read_grid: for b in transmute([]u8)input {
		defer i += 1

		switch b {
		case '.', 'O', '#', '@':
			if x >= int(max(u16)) do return {}, .Wide_Grid
			defer x += 1

			switch b {
			case '.': append(&cells, Day15_Cell.Empty)
			case 'O': append(&cells, Day15_Cell.Box)
			case '#': append(&cells, Day15_Cell.Wall)

			case '@':
				if robot_pos != NO_ROBOT do return {}, .Multiple_Robots
				robot_pos = {u16(x), u16(y)}
				append(&cells, Day15_Cell.Empty)
			}

		case '\n':
			if x == 0 do break read_grid
			if x > int(max(u16)) do return {}, .Wide_Grid
			if w != 0 && int(w) != x do return {}, .Ragged_Grid
			w, x = u16(x), 0

			y += 1
			if y > int(max(u16)) do return {}, .Tall_Grid
			h = u16(y)

		case:
			fmt.eprintln("bad", u8(b))
			return {}, .Invalid_Cell
		}
	}

	assert(len(cells) == int(w)*int(h))
	if robot_pos == NO_ROBOT do return {}, .No_Robot

	instructions : [dynamic]Day15_Instruction
	defer if result.instructions == nil do delete(instructions)

	for b in transmute([]u8)input[i:] {
		switch b {
		case '^': append(&instructions, Day15_Instruction.N)
		case '>': append(&instructions, Day15_Instruction.E)
		case 'v': append(&instructions, Day15_Instruction.S)
		case '<': append(&instructions, Day15_Instruction.W)
		case '\n':

		case: return {}, .Invalid_Instruction
		}
	}

	shrink(&cells)
	shrink(&instructions)

	result = {
		size = {w, h},
		robot_pos = robot_pos,
		cells = cells[:],
		instructions = instructions[:],
	}
	return
}

day15_part1 :: proc (input: Day15_Input) -> (result: int) {
	cells := make([]Day15_Cell, len(input.cells))
	defer delete(cells)
	copy(cells, input.cells)

	robot_idx := int(input.robot_pos.x) + int(input.robot_pos.y) * int(input.size.x)

	for instruction, n in input.instructions {
		step : int
		switch instruction {
		case .N: step = -int(input.size.x)
		case .E: step = +1
		case .S: step = +int(input.size.x)
		case .W: step = -1
		case: unreachable()
		}

		pushing := false
		move_scan: for i := robot_idx+step;; i += step {
			switch cells[i] {
			case .Box:
				pushing = true
				continue

			case .Wall:
			case .Empty:
				robot_idx += step
				if pushing {
					cells[i] = .Box
					cells[robot_idx] = .Empty
				}

			case: unreachable()
			}

			break
		}
	}

	for cell, i in cells {
		if cell != .Box do continue
		x := i % int(input.size.x)
		y := i / int(input.size.x)
		result += x + 100 * y
	}

	return
}

day15_part2 :: proc (input: Day15_Input) -> (result: int) {
	cells := make([]Day15_Wide_Cell, 2*len(input.cells))
	defer delete(cells)

	for &c, i in slice.reinterpret([][2]Day15_Wide_Cell, cells[:]) {
		switch input.cells[i] {
		case .Empty: c = {.Empty, .Empty}
		case .Box: c = {.Box_Left, .Box_Right}
		case .Wall: c = {.Wall, .Wall}
		case: unreachable()
		}
	}

	push_horizontal :: proc (cells: []Day15_Wide_Cell, start_idx: int, dir: i8) -> bool {
		assert(dir == -1 || dir == 1)
		for i := start_idx+int(dir);; i += int(dir) {
			switch cells[i] {
			case .Box_Left, .Box_Right: continue
			case .Wall: return false
			case .Empty:
				if dir < 0 do copy(cells[i:start_idx], cells[1:][i:start_idx])
				else do copy(cells[1:][start_idx:i], cells[start_idx:i])
				cells[start_idx] = .Empty
				return true

			case: unreachable()
			}
		}
	}

	push_vertical :: proc (cells: []Day15_Wide_Cell, start_idx: int, stride: int) -> bool {
		assert(stride != 0)
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

		moves := make([dynamic]int, context.temp_allocator)

		append(&moves, start_idx + stride)
		#partial switch cells[start_idx + stride] {
		case .Box_Left: append(&moves, start_idx + stride + 1)
		case .Box_Right: append(&moves, start_idx + stride - 1)
		}

		for i := 0; i < len(moves); i += 1 {
			j := moves[i]
			switch cells[j] {
			case .Box_Left:
				append(&moves, j + stride)
				if cells[j+stride] == .Box_Right do append(&moves, j + stride - 1)
			
			case .Box_Right:
				append(&moves, j + stride)
				if cells[j+stride] == .Box_Left do append(&moves, j + stride + 1)

			case .Wall: return false
			case .Empty: continue

			case: unreachable()
			}
		}

		#reverse for i in moves {
			#partial switch cells[i] {
			case .Box_Left, .Box_Right:
				cells[i+stride] = cells[i]
				cells[i] = .Empty
			}
		}

		return true
	}

	stride := 2*int(input.size.x)
	robot_idx := 2 * int(input.robot_pos.x) + int(input.robot_pos.y) * stride

	for instruction, n in input.instructions {
		switch instruction {
		case .N: if push_vertical(cells, robot_idx, -stride) do robot_idx -= stride
		case .E: if push_horizontal(cells, robot_idx, +1) do robot_idx += 1
		case .S: if push_vertical(cells, robot_idx, +stride) do robot_idx += stride
		case .W: if push_horizontal(cells, robot_idx, -1) do robot_idx -= 1
		case: unreachable()
		}
	}

	for cell, i in cells {
		if cell != .Box_Left do continue
		x := i % stride
		y := i / stride
		result += x + 100 * y
	}

	return
}

DAY15_EXAMPLE_SMALL ::
`########
#..O.O.#
##@.O..#
#...O..#
#.#.O..#
#...O..#
#......#
########

<^^>>>vv<v>>v<<`

DAY15_EXAMPLE_LARGE ::
`##########
#..O..O.O#
#......O.#
#.OO..O.O#
#..O@..O.#
#O#..O...#
#O..O..O.#
#.OO.O.OO#
#....O...#
##########

<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^`

@test
day15_test_small :: proc (t: ^testing.T) {
	input, input_err := day15_parse(DAY15_EXAMPLE_SMALL)
	defer delete(input.cells)
	defer delete(input.instructions)
	testing.expect_value(t, input_err, nil)

	p1 := day15_part1(input)
	testing.expect_value(t, p1, 2028)
}

@test
day15_test_large :: proc (t: ^testing.T) {
	input, input_err := day15_parse(DAY15_EXAMPLE_LARGE)
	defer delete(input.cells)
	defer delete(input.instructions)
	testing.expect_value(t, input_err, nil)

	p1 := day15_part1(input)
	testing.expect_value(t, p1, 10092)

	p2 := day15_part2(input)
	testing.expect_value(t, p2, 9021)
}

