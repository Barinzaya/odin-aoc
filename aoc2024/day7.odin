package aoc2024

import "base:intrinsics"
import "core:fmt"
import "core:math/bits"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

Day7_Equation :: struct {
	result: u64,
	data: [2]u64,
}

Day7_Input_Error :: enum {
	Ok,
	Invalid_Result,
	Invalid_Value,
	No_Values,
	Too_Many_Values,
}

day7 :: proc (input: string) {
	t := time.tick_now()

	equations, input_err := day7_parse(input)
	defer delete(equations)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day7_part1(equations[:])
	p1_dur := time.tick_lap_time(&t)

	p2 := day7_part2(equations[:])
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day7_parse :: proc (input: string, allocator := context.allocator) -> (equations: [dynamic]Day7_Equation, error: Day7_Input_Error) {
	defer if error != nil {
		delete(equations)
		equations = {}
	}

	equations = make([dynamic]Day7_Equation, allocator)

	remainder := input
	for len(remainder) > 0 {
		equation : Day7_Equation
		i : int

		equation.result, _ = strconv.parse_u64(remainder, 10, &i)
		if i == 0 do return equations, .Invalid_Result
		remainder = remainder[i:]

		if len(remainder) == 0 || remainder[0] != ':' do return equations, .Invalid_Result
		remainder = remainder[1:]

		data : u64
		shift := 0
		word := 0

		for len(remainder) > 0 && remainder[0] != '\n' {
			if word >= len(equation.data) do return equations, .Too_Many_Values
			remainder = remainder[1:]

			value, _ := strconv.parse_uint(remainder, 10, &i)
			if i == 0 do return equations, .Invalid_Value
			if value >= (1 << 10) do return equations, .Invalid_Value

			data |= u64(value) << uint(shift)
			remainder = remainder[i:]
			shift += 10

			if shift >= 60 {
				equation.data[word] = data
				data = 0
				shift = 0
				word += 1
			}
		}

		if shift == 0 && word == 0 do return equations, .No_Values
		if len(remainder) > 0 do remainder = remainder[1:]

		if data != 0 {
			equation.data[word] = data
		}

		append(&equations, equation)
	}

	return
}

day7_part1 :: proc (equations: []Day7_Equation) -> (result: u64) {
	check :: proc (a, b, total, target: u64) -> bool {
		a, b := a, b
		if a == 0 do a, b = b, 0
		if a == 0 do return total == target

		next := a & 0x3ff
		a >>= 10

		if sum, over := bits.overflowing_add(total, next); !over {
			if check(a, b, sum, target) do return true
		}

		if product, over := bits.overflowing_mul(total, next); !over {
			if check(a, b, product, target) do return true
		}

		return false
	}

	for &equation in equations {
		a, b := expand_values(equation.data)
		target := equation.result

		first := a & 0x3ff
		a >>= 10

		if check(a, b, first, target) do result += target
	}

	return
}

day7_part2 :: proc (equations: []Day7_Equation) -> (result: u64) {
	check :: proc (a, b, total, target: u64) -> bool {
		a, b := a, b
		if a == 0 do a, b = b, 0
		if a == 0 do return total == target

		next := a & 0x3ff
		a >>= 10

		if sum, over := bits.overflowing_add(total, next); !over {
			if check(a, b, sum, target) do return true
		}

		if product, over := bits.overflowing_mul(total, next); !over {
			if check(a, b, product, target) do return true
		}

		do_concat: {
			concat : u64
			over: bool

			switch {
			case next <= 9: concat, over = bits.overflowing_mul(total, 10)
			case next <= 99: concat, over = bits.overflowing_mul(total, 100)
			case next <= 999: concat, over = bits.overflowing_mul(total, 1000)

			case: unreachable()
			}

			if intrinsics.expect(over, false) do break do_concat

			concat, over = bits.overflowing_add(concat, next)
			if intrinsics.expect(over, false) do break do_concat

			if check(a, b, concat, target) do return true
		}

		return false
	}

	for &equation in equations {
		a, b := expand_values(equation.data)
		target := equation.result

		first := a & 0x3ff
		a >>= 10

		if check(a, b, first, target) do result += target
	}

	return
}

DAY7_EXAMPLE ::
`190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20`

@test
test_day7 :: proc (t: ^testing.T) {
	equations, input_err := day7_parse(DAY7_EXAMPLE)
	testing.expect_value(t, input_err, nil)
	defer delete(equations)

	p1 := day7_part1(equations[:])
	testing.expect_value(t, p1, 3749)

	p2 := day7_part2(equations[:])
	testing.expect_value(t, p2, 11387)
}

