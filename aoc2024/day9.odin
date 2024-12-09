package aoc2024

import "core:fmt"
import "core:strings"
import "core:testing"
import "core:time"

day9 :: proc (input: string) {
	input := input
	input = strings.trim_right_space(input)

	t := time.tick_now()

	p1 := day9_part1(input)
	p1_dur := time.tick_lap_time(&t)

	p2 := day9_part2(input)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day9_score :: #force_inline proc (file, block, size: int) -> int {
	return file * (size * block + size * (size-1) / 2)
}

day9_part1 :: proc (input: string) -> (result: int) {
	assert (len(input) % 2 == 1)
	block, start, end := 0, 0, len(input)-1
	ready := int(input[end] - '0')

	for ; start < end; start += 2 {
		ignored := int(input[start] - '0')
		result += day9_score(start/2, block, ignored)
		block += ignored

		space := int(input[start+1] - '0')
		for start < end && space > 0 {
			copied := min(ready, space)
			result += day9_score(end/2, block, copied)

			block += copied
			ready -= copied
			space -= copied

			if ready == 0 {
				end -= 2
				ready = int(input[end] - '0')
			}
		}

		if space > 0 do ready = 0
	}

	result += day9_score(end/2, block, ready)
	return
}

day9_part2 :: proc (input: string) -> (result: int) {
	Slot :: bit_field int {
		size: int | 4,
		block: int | 28,
	}

	offsets := make([]int, len(input))
	defer delete(offsets)

	spaces := make([]u8, len(input)/2)
	defer delete(spaces)

	block := int(input[0] - '0')
	for i := 1; i < len(input); i += 2 {
		space := input[i] - '0'
		offsets[i] = block
		spaces[i/2] = space
		block += int(space)

		offsets[i+1] = block
		block += int(input[i+1] - '0')
	}

	outer: for i := len(input)-1; i >= 0; i -= 2 {
		size := input[i] - '0'

		for &space, j in spaces[:i/2] {
			if space < size do continue

			slot := 2*j + 1
			result += day9_score(i/2, offsets[slot], int(size))

			offsets[slot] += int(size)
			space -= size
			continue outer
		}

		result += day9_score(i/2, offsets[i], int(size))
	}

	return
}

@test
day9_example :: proc (t: ^testing.T) {
	input :: "2333133121414131402"

	p1 := day9_part1(input)
	testing.expect_value(t, p1, 1928)

	p2 := day9_part2(input)
	testing.expect_value(t, p2, 2858)
}

