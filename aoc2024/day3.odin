package aoc2024

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

day3 :: proc (input: string) {
	t := time.tick_now()

	p1 := day3_part1(input)
	p1_dur := time.tick_lap_time(&t)

	p2 := day3_part2(input)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day3_part1 :: proc (input: string) -> (result: int) {
	input := input
	for {
		i := strings.index(input, "mul(")
		if i < 0 do break
		input = input[i+4:]

		a, _ := strconv.parse_uint(input, 10, &i)
		if i == 0 do continue
		input = input[i:]

		if len(input) < 3 || input[0] != ',' do continue
		input = input[1:]

		b, _ := strconv.parse_uint(input, 10, &i)
		if i == 0 do continue
		input = input[i:]

		if len(input) < 1 || input[0] != ')' do continue
		input = input[1:]

		result += int(a * b)
	}

	return
}

day3_part2 :: proc (input: string) -> (result: int) {
	enabled := true

	left := input
	for len(left) >= 4 {
		switch {
		case strings.has_prefix(left, "mul("):
			left = left[4:]
			if !enabled do continue

			i : int

			a, _ := strconv.parse_uint(left, 10, &i)
			if i == 0 do continue
			left = left[i:]

			if len(left) < 3 || left[0] != ',' do continue
			left = left[1:]

			b, _ := strconv.parse_uint(left, 10, &i)
			if i == 0 do continue
			left = left[i:]

			if len(left) < 1 || left[0] != ')' do continue
			left = left[1:]

			result += int(a * b)

		case strings.has_prefix(left, "do()"):
			left = left[4:]
			enabled = true

		case strings.has_prefix(left, "don't()"):
			left = left[7:]
			enabled = false

		case:
			left = left[1:]
		}
	}

	return
}

@test
test_day3_part1 :: proc (t: ^testing.T) {
	testing.expect_value(t, day3_part1("xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"), 161)
}

@test
test_day3_part2 :: proc (t: ^testing.T) {
	testing.expect_value(t, day3_part2("xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"), 48)
}

