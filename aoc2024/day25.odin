package aoc2024

import "core:fmt"
import "core:os"
import "core:testing"
import "core:time"

Day25_Input :: struct {
	keys: [dynamic][5]u8,
	locks: [dynamic][5]u8,
}

Day25_Input_Error :: enum {
	Ok,
	Invalid_Column,
	Invalid_Schematic,
}

day25 :: proc (input: string) {
	t := time.tick_now()

	schematics, err := day25_parse(input, context.temp_allocator)
	if err != nil {
		fmt.eprintln("Falied to parse input:", err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day25_part1(schematics)
	p1_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
}

day25_part1 :: proc (schematics: Day25_Input) -> (result: u64) {
	for key in schematics.keys {
		next_lock: for lock in schematics.locks {
			sum := key + lock
			for s in sum do if s > 7 do continue next_lock
			result += 1
		}
	}
	return
}

day25_parse :: proc (input: string, allocator := context.allocator) -> (result: Day25_Input, err: Day25_Input_Error) {
	W, H :: 5, 7
	STRIDE :: W+1

	result.keys  = make([dynamic][5]u8, allocator)
	result.locks = make([dynamic][5]u8, allocator)

	for i := 0; i+STRIDE*H-1 <= len(input); i += STRIDE*H + 1 {
		block := input[i:][:STRIDE*H-1]

		is_key, is_lock : bool
		num_bot, num_top : [W]u8

		for x in 0..<W {
			y : int
			for /**/; y < H && block[STRIDE*y + x] == '#'; y += 1 {
				num_top[x] += 1
				is_lock = true
			}

			for /**/; y < H && block[STRIDE*y + x] == '.'; y += 1 do continue

			for /**/; y < H && block[STRIDE*y + x] == '#'; y += 1 {
				num_bot[x] += 1
				is_key = true
			}

			if num_top[x] == H do num_bot[x] = H
			if y < H do return {}, .Invalid_Column
		}

		if is_key == is_lock do return {}, .Invalid_Schematic
		if is_key {
			append(&result.keys, num_bot)
		} else {
			append(&result.locks, num_top)
		}
	}

	return
}

DAY25_EXAMPLE ::
`#####
.####
.####
.####
.#.#.
.#...
.....

#####
##.##
.#.##
...##
...#.
...#.
.....

.....
#....
#....
#...#
#.#.#
#.###
#####

.....
.....
#.#..
###..
###.#
###.#
#####

.....
.....
.....
#....
#.#..
#.#.#
#####`

@test
day25_test :: proc (t: ^testing.T) {
	schematics, err := day25_parse(DAY25_EXAMPLE, context.temp_allocator)
	testing.expect_value(t, err, nil)

	p1 := day25_part1(schematics)
	testing.expect_value(t, p1, 3)
}

