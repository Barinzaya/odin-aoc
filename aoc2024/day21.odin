package aoc2024

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:testing"
import "core:time"

Day21_Input :: struct {
	keys: [dynamic][dynamic]Day21_Num_Key,
}

Day21_Input_Error :: enum {
	Ok,
	Invalid_Key,
}

Day21_Dir_Key :: enum u8 {
	Enter,
	Up, Down, Left, Right,
}

Day21_Num_Key :: enum u8 {
	Enter,
	_0, _1, _2, _3, _4, _5, _6, _7, _8, _9,
}

@rodata
day21_dir_pos := [Day21_Dir_Key][2]i8 {
	.Enter = { 0,  0},
	.Up    = {-1,  0},
	.Down  = {-1, -1},
	.Left  = {-2, -1},
	.Right = { 0, -1},
}

@rodata
day21_num_pos := [Day21_Num_Key][2]i8 {
	.Enter = { 0, 0},
	._0    = {-1, 0},
	._1    = {-2, 1},
	._2    = {-1, 1},
	._3    = { 0, 1},
	._4    = {-2, 2},
	._5    = {-1, 2},
	._6    = { 0, 2},
	._7    = {-2, 3},
	._8    = {-1, 3},
	._9    = { 0, 3},
}

day21 :: proc (input: string) {
	t := time.tick_now()

	codes, err := day21_parse(input, context.temp_allocator)
	if err != nil {
		fmt.eprintln("Failed to parse input", err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day21_solve(codes, 2)
	p1_dur := time.tick_lap_time(&t)

	p2 := day21_solve(codes, 25)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day21_parse :: proc (input: string, allocator := context.allocator) -> (result: [][]Day21_Num_Key, err: Day21_Input_Error) {
	codes := make([dynamic][]Day21_Num_Key, allocator)
	defer if err != nil {
		for c in codes do delete(c)
		delete(codes)
	}
	keys := make([dynamic]Day21_Num_Key, allocator)
	defer delete(keys)

	for b in transmute([]u8)input {
		switch b {
		case '0'..='9': append(&keys, transmute(Day21_Num_Key)(b - '0') + ._0)
		case 'A': append(&keys, Day21_Num_Key.Enter)
		case '\n':
			append(&codes, keys[:])
			keys = make([dynamic]Day21_Num_Key, allocator)

		case: return nil, .Invalid_Key
		}
	}

	if len(keys) > 0 do append(&codes, keys[:])
	return codes[:], nil
}

day21_solve :: proc (codes: [][]Day21_Num_Key, indirections: int) -> (result: u64) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	costs_a, costs_b : [Day21_Dir_Key][Day21_Dir_Key]u64

	calculate_cost :: proc (costs: ^[Day21_Dir_Key][Day21_Dir_Key]u64, from, to: [2]i8) -> u64 {
		xy_cost, yx_cost : u64
		xy_key, yx_key : Day21_Dir_Key
		delta := to - from

		if delta.x != 0 {
			new_key := Day21_Dir_Key.Left if delta.x < 0 else .Right
			xy_cost += costs[xy_key][new_key] + u64(abs(delta.x))
			xy_key = new_key
		}

		if delta.y != 0 {
			new_key := Day21_Dir_Key.Down if delta.y < 0 else .Up
			xy_cost += costs[xy_key][new_key] + u64(abs(delta.y))
			yx_cost += costs[yx_key][new_key] + u64(abs(delta.y))
			xy_key, yx_key = new_key, new_key
		}

		if delta.x != 0 {
			new_key := Day21_Dir_Key.Left if delta.x < 0 else .Right
			yx_cost += costs[yx_key][new_key] + u64(abs(delta.x))
			yx_key = new_key
		}

		xy_cost += costs[xy_key][.Enter]
		yx_cost += costs[yx_key][.Enter]

		if from.y == 0 && to.x == -2 do xy_cost = max(u64)
		if to.y == 0 && from.x == -2 do yx_cost = max(u64)
		return min(xy_cost, yx_cost)
	}

	costs, costs_new := &costs_a, &costs_b
	for i in 0..<indirections {
		for from in Day21_Dir_Key do for to in Day21_Dir_Key {
			costs_new[from][to] = calculate_cost(costs, day21_dir_pos[from], day21_dir_pos[to])
		}

		costs, costs_new = costs_new, costs
	}

	for code in codes {
		cost, value : u64
		pos : [2]i8

		for num_key in code {
			if ._0 <= num_key && num_key <= ._9 {
				value = (value * 10) + u64(transmute(u8)(num_key - ._0))
			}

			new_pos := day21_num_pos[num_key]
			cost += calculate_cost(costs, pos, new_pos) + 1
			pos = new_pos
		}

		result += cost * value
	}

	return
}

/*
1 [.Enter = [.Enter = 0, .Up = 1, .Down = 2, .Left = 3, .Right = 1], .Up = [
.Enter = 1, .Up = 0, .Down = 1, .Left = 2, .Right = 2], .Down = [.Enter = 2, .Up = 1, .Down = 0, .Left = 1, .Right = 1], .Left = [.Enter = 3, .Up = 2, .Down = 1, .Left = 0, .Right = 2], .Right = [.Enter = 1, .Up = 2, .Down = 1, .Left = 2, .Right = 0]]
2 [.Enter = [.Enter = 0, .Up = 7, .Down = 8, .Left = 9, .Right = 5], .Up = [.Enter = 3, .Up = 0, .Down = 5, .Left = 8, .Right = 6], .Down = [.Enter = 6, .Up = 3, .Down = 0, .Left = 7, .Right = 3], .Left = [.Enter = 7, .Up = 6, .Down = 3, .Left = 0, .Right = 4], .Right = [.Enter = 3, .Up = 8, .Down = 7, .Left = 8, .Right = 0]]
_0 18 _2 12 _9 20 Enter 18 68 29
_9 14 _8 18 _0 18 Enter 10 60 980
_1 22 _7 13 _9 11 Enter 18 64 179
_4 23 _5 10 _6 10 Enter 17 60 456
_3 12 _7 23 _9 11 Enter 18 64 379

029A: <vA<AA>>^AvAA<^A>A<v<A>>^AvA^A<vA>^A<v<A>^A>AAvA^A<v<A>A>^AAAvA<^A>A
980A: <v<A>>^AAAvA^A<vA<AA>>^AvAA<^A>A<v<A>A>^AAAvA<^A>A<vA>^A<A>A
             ^        <<       A       ^^   A     >>   A        vvv      A
         <   A  v <   AA >>  ^ A   <   AA > A  v  AA ^ A   < v  AAA >  ^ A
179A: <v<A>>^A<vA<A>>^AAvAA<^A>A<v<A>>^AAvA^A<vA>^AA<A>A<v<A>A>^AAAvA<^A>A
456A: <v<A>>^AA<vA<A>>^AAvAA<^A>A<vA>^A<A>A<vA>^A<A>A<v<A>A>^AAvA<^A>A
379A: <v<A>>^AvA^A<vA<AA>>^AAvA<^A>AAvA^A<vA>^AA<A>A<v<A>A>^AAAvA<^A>A
*/

DAY21_EXAMPLE ::
`029A
980A
179A
456A
379A`

@test
day21_test :: proc (t: ^testing.T) {
	codes, err := day21_parse(DAY21_EXAMPLE, context.temp_allocator)
	testing.expect_value(t, err, nil)

	p1 := day21_solve(codes, 2)
	testing.expect_value(t, p1, 126384)
}

