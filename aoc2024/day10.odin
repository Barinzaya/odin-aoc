package aoc2024

import "core:container/bit_array"
import "core:fmt"
import "core:strings"
import "core:testing"
import "core:time"

day10 :: proc (input: string) {
	t := time.tick_now()

	p1 := day10_part1(input)
	p1_dur := time.tick_lap_time(&t)

	p2 := day10_part2(input)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day10_part1 :: proc (input: string) -> (result: int) {
	stride := strings.index_byte(input, '\n') + 1
	assert(stride > 0)

	visited : bit_array.Bit_Array
	bit_array.init(&visited, len(input))
	defer bit_array.destroy(&visited)

	for b, i in transmute([]u8)input {
		if b != '0' do continue

		visit :: proc (input: string, visited: ^bit_array.Bit_Array, i, stride: int, h: u8) -> (result: int) {
			if i < 0 || i >= len(input) do return
			if bit_array.get(visited, i) do return
			if input[i] - '0' != h do return

			bit_array.set(visited, i)
			if h == 9 do return 1
			
			result += visit(input, visited, i - 1, stride, h + 1)
			result += visit(input, visited, i + 1, stride, h + 1)
			result += visit(input, visited, i - stride, stride, h + 1)
			result += visit(input, visited, i + stride, stride, h + 1)
			return
		}

		bit_array.clear(&visited)
		result += visit(input, &visited, i, stride, 0)
	}

	return
}

day10_part2 :: proc (input: string) -> (result: int) {
	stride := strings.index_byte(input, '\n') + 1
	assert(stride > 0)

	visited : bit_array.Bit_Array
	bit_array.init(&visited, len(input))
	defer bit_array.destroy(&visited)

	for b, i in transmute([]u8)input {
		if b != '0' do continue

		visit :: proc (input: string, visited: ^bit_array.Bit_Array, i, stride: int, h: u8) -> (result: int) {
			if i < 0 || i >= len(input) do return
			if bit_array.get(visited, i) do return
			if input[i] - '0' != h do return
			if h == 9 do return 1
			
			bit_array.set(visited, i)
			result += visit(input, visited, i - 1, stride, h + 1)
			result += visit(input, visited, i + 1, stride, h + 1)
			result += visit(input, visited, i - stride, stride, h + 1)
			result += visit(input, visited, i + stride, stride, h + 1)
			bit_array.unset(visited, i)
			return
		}

		bit_array.clear(&visited)
		result += visit(input, &visited, i, stride, 0)
	}

	return
}

DAY10_EXAMPLE ::
`89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732`

@test
test_day10 :: proc (t: ^testing.T) {
	p1 := day10_part1(DAY10_EXAMPLE)
	testing.expect_value(t, p1, 36)

	p2 := day10_part2(DAY10_EXAMPLE)
	testing.expect_value(t, p2, 81)
}
