package aoc2024

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:time"

Input_Err :: enum {
	Invalid_Input,
}

Pair :: struct {
	a, b : int,
}

day1 :: proc (input: string) {
	t := time.tick_now()

	pairs, read_err := parse_input(input)
	defer delete(pairs)
	if read_err != nil {
		fmt.eprintln("Failed to read input:", read_err)
		os.exit(1)
	}

	read_dur := time.tick_lap_time(&t)
	fmt.println("Parsed input in", read_dur)

	n := len(pairs)
	slice.sort(pairs.a[:n])
	slice.sort(pairs.b[:n])

	sort_dur := time.tick_lap_time(&t)
	fmt.println("Sorted inputs in", sort_dur)

	p1 := day1_part1(pairs)
	p1_dur := time.tick_lap_time(&t)
	fmt.println("Part 1:", p1, "in", p1_dur)

	p2 := day1_part2(pairs)
	p2_dur := time.tick_lap_time(&t)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

parse_input :: proc (input: string) -> (pairs: #soa[dynamic]Pair, err: Input_Err) {
	n := (len(input) + 1) / 14
	reserve(&pairs, n)

	for i := 0; i+13 <= len(input); i += 14 {
		a, a_ok := strconv.parse_int(input[i:][:5], 10)
		if !a_ok do return pairs, .Invalid_Input

		b, b_ok := strconv.parse_int(input[i+8:][:5], 10)
		if !b_ok do return pairs, .Invalid_Input

		append(&pairs, Pair { a, b })
	}

	return
}

day1_part1 :: proc (pairs: #soa[dynamic]Pair) -> (result: int) {
	for pair in pairs {
		result += abs(pair.a - pair.b)
	}
	return 
}

day1_part2 :: proc (pairs: #soa[dynamic]Pair) -> (result: int) {
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
