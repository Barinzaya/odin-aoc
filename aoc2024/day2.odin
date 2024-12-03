package aoc2024

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

Day2_Input_Error :: enum {
	Invalid_Input,
	Level_Range,
}

day2 :: proc (input: string) {
	t := time.tick_now()

	reports, input_err := day2_parse(input)
	defer delete(reports)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}

	parse_dur := time.tick_lap_time(&t)

	p1 := day2_solve(reports[:], 0)
	p1_dur := time.tick_lap_time(&t)

	p2 := day2_solve(reports[:], 1)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed inputs in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day2_parse :: proc (input: string) -> (reports: [dynamic][8]u8, err: Day2_Input_Error) {
	left := input
	for line in strings.split_lines_iterator(&left) {
		report : [8]u8
		i := 0

		line_left := line
		for level in strings.split_iterator(&line_left, " ") {
			level, ok := strconv.parse_int(level, 10)
			if !ok do return reports, .Invalid_Input
			if level < 1 || level > int(max(u8)) do return reports, .Level_Range

			report[i] = u8(level)
			i += 1
		}

		if i > 0 do append(&reports, report)
	}

	return
}

day2_solve :: proc (reports: [][8]u8, num_dampens: u8) -> (result: int) {
	test_order :: proc (last: u8, levels: []u8, order: i8, num_dampens: u8) -> bool {
		last := last

		for level, i in levels {
			if level == 0 do break

			if num_dampens > 0 && test_order(last, levels[i+1:], order, num_dampens-1) {
				break
			}

			change := order * i8(level - last)
			if last == 0 || (1 <= change && change <= 3) {
				last = level
			} else {
				return false
			}
		}

		return true
	}

	for &report in reports {
		order : i8 = 1 if report[0] < report[1] else -1
		if test_order(0, report[:], order, num_dampens) || test_order(0, report[:], -order, num_dampens) {
			result += 1
		}
	}

	return
}

DAY2_EXAMPLE ::
`7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9`

@test
test_day2 :: proc (t: ^testing.T) {
	reports, parse_err := day2_parse(DAY2_EXAMPLE)
	defer delete(reports)

	testing.expect_value(t, parse_err, nil)
	testing.expect_value(t, day2_solve(reports[:], 0), 2)
	testing.expect_value(t, day2_solve(reports[:], 1), 4)
}

