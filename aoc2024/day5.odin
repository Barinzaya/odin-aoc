package aoc2024

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

Day5_Input :: struct {
	rules: [dynamic][2]u8,
	updates: [dynamic][24]u8,
}

Day5_Input_Error :: enum {
	Ok,
	Invalid_Page,
	Invalid_Rule,
	Page_Range,
	Update_Size,
}

day5 :: proc (input: string) {
	t := time.tick_now()

	input, input_err := day5_parse(input)
	defer delete(input.rules)
	defer delete(input.updates)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}

	parse_dur := time.tick_lap_time(&t)

	after : [100]bit_set[0..<100]
	for rule in input.rules {
		after[rule[0]] += { int(rule[1]) }
	}

	build_dur := time.tick_lap_time(&t)

	p1, p2 := day5_solve(input.updates[:], &after)
	solve_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Built dependency graph in", build_dur)
	fmt.println("Solved in", solve_dur)
	fmt.println("Part 1:", p1)
	fmt.println("Part 2:", p2)
}

day5_parse :: proc (input: string) -> (result: Day5_Input, err: Day5_Input_Error) {
	rules : [dynamic][2]u8
	defer if err != nil do delete(rules)

	left := input
	for line in strings.split_lines_iterator(&left) {
		if len(line) == 0 do break

		a_str, _, b_str := strings.partition(line, "|")
		if len(b_str) == 0 do return {}, .Invalid_Rule

		a, a_ok := strconv.parse_int(a_str)
		if !a_ok do return {}, .Invalid_Page
		if a < 1 || a > 99 do return {}, .Page_Range

		b, b_ok := strconv.parse_int(b_str)
		if !b_ok do return {}, .Invalid_Page

		append(&rules, [2]u8 { u8(a), u8(b) })
	}

	updates : [dynamic][24]u8
	defer if err != nil do delete(rules)

	for line in strings.split_lines_iterator(&left) {
		update : [24]u8
		i := 0

		line := line
		for part in strings.split_iterator(&line, ",") {
			page, page_ok := strconv.parse_int(part)
			if !page_ok do return {}, .Invalid_Page
			if page < 1 || page > 99 do return {}, .Page_Range
			if i >= len(update) do return {}, .Update_Size

			update[i] = u8(page)
			i += 1
		}

		if i == 0 do return {}, .Update_Size
		append(&updates, update)
	}

	return {rules, updates}, nil
}

day5_solve :: proc (updates: [][24]u8, after: ^[100]bit_set[0..<100]) -> (p1, p2: int) {
	for &update in updates {
		bad := false
		n : int
		previous : bit_set[0..<100]

		for page, i in update {
			if page == 0 {
				n = i
				break
			}

			if after[page] & previous != {} do bad = true
			previous += { int(page) }
		}

		if bad {
			context.user_ptr = after

			slice.sort_by(update[:n], proc (a, b: u8) -> bool {
				after := cast(^[100]bit_set[0..<100])context.user_ptr
				return int(b) in after[a]
			})

			p2 += int(update[n/2])
		} else {
			p1 += int(update[n/2])
		}
	}

	return
}

DAY5_EXAMPLE ::
`47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47`

@test
test_day5 :: proc (t: ^testing.T) {
	input, input_err := day5_parse(DAY5_EXAMPLE)
	defer delete(input.rules)
	defer delete(input.updates)
	testing.expect_value(t, input_err, nil)

	after : [100]bit_set[0..<100]
	for rule in input.rules {
		after[rule[0]] += { int(rule[1]) }
	}

	p1, p2 := day5_solve(input.updates[:], &after)
	testing.expect_value(t, p1, 143)
	testing.expect_value(t, p2, 123)
}

