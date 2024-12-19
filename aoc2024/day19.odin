package aoc2024

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"
import "core:time"

Day19_Color :: enum u8 { Black, Blue, Green, Red, White }

Day19_Input :: struct {
	towels: []string,
	patterns: []string,
}

day19 :: proc (input: string) {
	t := time.tick_now()

	input, ok := day19_parse(input)
	defer delete(input.patterns)
	defer delete(input.towels)
	if !ok {
		fmt.eprintln("Failed to parse input!")
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1, p2 := day19_solve(input)
	solve_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Solved in", solve_dur)
	fmt.println("Part 1:", p1)
	fmt.println("Part 2:", p2)
}

day19_parse_color :: proc (c: u8) -> (Day19_Color, bool) {
	switch c {
	case 'b': return .Black, true
	case 'g': return .Green, true
	case 'r': return .Red, true
	case 'u': return .Blue, true
	case 'w': return .White, true
	case: return nil, false
	}
}

day19_parse :: proc (input: string) -> (result: Day19_Input, ok: bool) {
	left := input
	first := strings.split_lines_iterator(&left) or_return

	towels : [dynamic]string
	defer if !ok do delete(towels)

	left_towels := first
	for towel in strings.split_by_byte_iterator(&left_towels, ',') {
		append(&towels, strings.trim_space(towel))
	}

	patterns : [dynamic]string
	defer if !ok do delete(patterns)

	for pattern in strings.split_lines_iterator(&left) {
		if len(pattern) == 0 do continue
		append(&patterns, pattern)
	}

	return { towels = towels[:], patterns = patterns[:] }, true
}

day19_solve :: proc (input: Day19_Input) -> (p1, p2: int) {
	Node :: struct {
		children: [Day19_Color]^Node,
		leaf: bool,
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	root : Node

	for towel in input.towels {
		at := &root

		for b in transmute([]u8)towel {
			color := day19_parse_color(b) or_else panic("Bad color")
			next := at.children[color]

			if next == nil {
				next = new(Node, context.temp_allocator)
				at.children[color] = next
			}

			at = next
		}

		at.leaf = true
	}

	counts := make([dynamic]int, context.temp_allocator)

	for pattern in input.patterns {
		resize(&counts, len(pattern) + 1)
		counts[0] = 1
		slice.fill(counts[1:], 0)

		for i in 0..<len(pattern) {
			at := &root
			for j in i..<len(pattern) {
				color := day19_parse_color(pattern[j]) or_else panic("Bad color")
				at = at.children[color]
				if at == nil do break
				if at.leaf do counts[j+1] += counts[i]
			}
		}

		n := counts[len(pattern)]
		if n > 0 do p1 += 1
		p2 += n
	}

	return
}

DAY19_EXAMPLE ::
`r, wr, b, g, bwu, rb, gb, br

brwrr
bggr
gbbr
rrbgbr
ubwu
bwurrg
brgr
bbrgwb`

@test
day19_test :: proc (t: ^testing.T) {
	input, ok := day19_parse(DAY19_EXAMPLE)
	defer delete(input.patterns)
	defer delete(input.towels)
	testing.expect(t, ok)

	slice.sort(input.towels)

	p1, p2 := day19_solve(input)
	testing.expect_value(t, p1, 6)
	testing.expect_value(t, p2, 16)
}

