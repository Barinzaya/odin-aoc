package aoc2024

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

Day11_Input_Error :: enum {
	Ok,
	Invalid_Value,
}

day11 :: proc (input: string) {
	t := time.tick_now()

	values, input_err := day11_parse(input)
	defer delete(values)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}

	parse_dur := time.tick_lap_time(&t)

	p1 := day11_part1(values[:])
	p1_dur := time.tick_lap_time(&t)

	p2 := day11_part2(values[:])
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day11_parse :: proc (input: string) -> (result: [dynamic]u64, error: Day11_Input_Error) {
	values : [dynamic]u64
	defer if error != nil do delete(values)

	left := input
	for len(left) > 0 {
		read : int
		value, _ := strconv.parse_u64(left, 10, &read)
		if read == 0 {
			fmt.println(left)
			return nil, .Invalid_Value
		}

		left = left[read:]
		left = strings.trim_left_space(left)
		append(&values, value)
	}
	
	return values, nil
}

day11_part1 :: proc (values: []u64) -> (result: u64) {
	result += day11_solve(values, 25)
	return
}

day11_part2 :: proc (values: []u64) -> (result: u64) {
	result += day11_solve(values, 75)
	return
}

Day11_Step_Result :: union {
	u64,
	[2]u64,
}

day11_solve :: proc (values: []u64, steps: int) -> (result: u64) {
	a, b : map[u64]u64
	defer delete(a)
	defer delete(b)

	for v in values {
		a[v] += 1
	}

	for _ in 0..<steps {
		for v, n in a {
			switch next in day11_step(v) {
			case u64:
				b[next] += n

			case [2]u64:
				b[next[0]] += n
				b[next[1]] += n
			}
		}

		a, b = b, a
		clear(&b)
	}

	for _, n in a {
		result += n
	}

	return
}

day11_step :: proc (value: u64) -> Day11_Step_Result {
	if value == 0 do return 1

	log10 := ilog10_u64(value)
	if log10 % 2 == 1 {
		@(static, rodata)
		quotients := [10]u64 { 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10 }

		q := quotients[log10 / 2]
		return [2]u64 { value / q, value % q }
	} else {
		return 2024 * value
	}
}

@test
day11_example :: proc (t: ^testing.T) {
	values, input_err := day11_parse("125 17")
	defer delete(values)
	testing.expect_value(t, input_err, nil)

	testing.expect_value(t, len(values), 2)
	testing.expect_value(t, values[0], 125)
	testing.expect_value(t, values[1], 17)

	p1 := day11_part1(values[:])
	testing.expect_value(t, p1, 55312)
}

