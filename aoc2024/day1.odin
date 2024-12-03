package aoc2024

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:time"

Day1_Input_Err :: enum {
	Invalid_Input,
}

Day1_Pair :: struct {
	a, b : int,
}

day1 :: proc (input: string) {
	t := time.tick_now()

	pairs, input_err := day1_parse(input)
	defer delete(pairs)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}

	parse_dur := time.tick_lap_time(&t)

	n := len(pairs)
	slice.sort(pairs.a[:n])
	slice.sort(pairs.b[:n])
	sort_dur := time.tick_lap_time(&t)

	p1 := day1_part1(pairs[:])
	p1_dur := time.tick_lap_time(&t)

	p2 := day1_part2(pairs[:])
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Sorted inputs in", sort_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day1_parse :: proc (input: string) -> (pairs: #soa[dynamic]Day1_Pair, err: Day1_Input_Err) {
	n := (len(input) + 1) / 14
	reserve(&pairs, n)

	for i := 0; i+13 <= len(input); i += 14 {
		a, a_ok := strconv.parse_int(input[i:][:5], 10)
		if !a_ok do return pairs, .Invalid_Input

		b, b_ok := strconv.parse_int(input[i+8:][:5], 10)
		if !b_ok do return pairs, .Invalid_Input

		append(&pairs, Day1_Pair { a, b })
	}

	return
}

day1_part1 :: proc (pairs: #soa[]Day1_Pair) -> (result: int) {
	for pair in pairs {
		result += abs(pair.a - pair.b)
	}
	return 
}

day1_part2 :: proc (pairs: #soa[]Day1_Pair) -> (result: int) {
	n := len(pairs)
	for i, j := 0, 0; i < n; i += 1 {
		a := pairs.a[i]
		for j < n && pairs.b[j] < a do j += 1

		j0 := j
		for j < n && pairs.b[j] == a do j += 1

		result += (j - j0) * a
	}
	return 
}
