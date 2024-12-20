package aoc2024

import ba "core:container/bit_array"
import pq "core:container/priority_queue"
import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:testing"
import "core:time"

Day16_Metrics :: struct {
	size: [2]u16,
	start: [2]u16,
	end: [2]u16,
}

Day16_Metrics_Error :: enum u8 {
	Ok,
	Bad_Cell,
	Ragged_Grid,
	Tall_Grid,
	Wide_Grid,
	No_Start,
	No_End,
	Multiple_Starts,
	Multiple_Ends,
}

day16 :: proc (input: string) {
	t := time.tick_now()

	metrics, input_err := day16_parse(input)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1, p2 := day16_solve(input, metrics)
	solve_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Solved in", solve_dur)
	fmt.println("Part 1:", p1)
	fmt.println("Part 2:", p2)
}

day16_parse :: proc (input: string) -> (result: Day16_Metrics, err: Day16_Metrics_Error) {
	MAX_POS :: 1 << 15
	NO_POS :: [2]u16 { max(u16), max(u16) }
	result.start = NO_POS
	result.end = NO_POS

	x, y : int
	for b in input {
		switch b {
		case 'S':
			if result.start != NO_POS do return {}, .Multiple_Starts
			result.start = {u16(x), u16(y)}
			x += 1

		case 'E':
			if result.end != NO_POS do return {}, .Multiple_Ends
			result.end = {u16(x), u16(y)}
			x += 1

		case '\n':
			if result.size.x == 0 {
				if x > int(MAX_POS) do return {}, .Wide_Grid
				result.size.x = u16(x)
			} else if x != int(result.size.x) {
				return {}, .Ragged_Grid
			}

			x = 0
			y += 1
			if y > int(MAX_POS) do return {}, .Tall_Grid

		case '#', '.': x += 1
		case: return {}, .Bad_Cell
		}
	}

	if result.start == NO_POS do return {}, .No_Start
	if result.end == NO_POS do return {}, .No_End

	if x != 0 {
		x = 0
		y += 1
		if y > int(MAX_POS) do return {}, .Tall_Grid
	}
	result.size.y = u16(y)

	return
}

day16_solve :: proc (input: string, metrics: Day16_Metrics) -> (p1, p2: uint) {
	Dir :: enum u8 { N, E, S, W }
	Candidate :: struct {
		index: u32,
		score: u32,
		dir: Dir,
	}

	candidate_less :: proc (a, b: Candidate) -> bool { return a.score < b.score }
	candidate_swap :: proc (s: []Candidate, i, j: int) { s[i], s[j] = s[j], s[i] }

	dir_left  :: proc (dir: Dir) -> Dir { return transmute(Dir)((transmute(u8)dir - 1) % 4) }
	dir_right :: proc (dir: Dir) -> Dir { return transmute(Dir)((transmute(u8)dir + 1) % 4) }

	@(static, rodata)
	dir_offsets := [Dir][2]i8 {
		.N = { 0, -1},
		.E = {+1,  0},
		.S = { 0, +1},
		.W = {-1,  0},
	}

	best := make([][Dir]u32, len(input))
	defer delete(best)
	for &bs in best do for &b in bs do b = max(u32)

	prev := make([][Dir][Dir]u32, len(input))
	defer delete(prev)

	candidates : pq.Priority_Queue(Candidate)
	defer pq.destroy(&candidates)
	pq.init(&candidates, candidate_less, candidate_swap)

	stride := int(metrics.size.x) + 1
	start_index := u32(metrics.start.x) + u32(metrics.start.y) * u32(stride)

	best[start_index] = {}
	pq.push(&candidates, Candidate { index = start_index, dir = .E, score = 0 })
	pq.push(&candidates, Candidate { index = start_index, dir = .N, score = 1000 })
	pq.push(&candidates, Candidate { index = start_index, dir = .S, score = 1000 })
	pq.push(&candidates, Candidate { index = start_index, dir = .W, score = 2000 })

	p1 = max(uint)

	for cand in pq.pop_safe(&candidates) {
		if p1 <= uint(cand.score) do break

		fwd_offset := dir_offsets[cand.dir]
		fwd_step := int(fwd_offset.x) + int(fwd_offset.y) * stride
		right_step := int(-fwd_offset.y) + int(fwd_offset.x) * stride

		pos := int(cand.index) + fwd_step
		score := cand.score + 1
		for {
			switch input[pos] {
			case 'E':
				if score < best[pos][cand.dir] {
					best[pos][cand.dir] = score
					prev[pos][cand.dir] = {}
				}

				if score == best[pos][cand.dir] {
					assert(prev[pos][cand.dir][cand.dir] == 0 || prev[pos][cand.dir][cand.dir] == cand.index)
					prev[pos][cand.dir][cand.dir] = cand.index
				}

				p1 = min(p1, uint(score))

			case '.':
				if input[pos + right_step] == '#' && input[pos - right_step] == '#' {
					pos += fwd_step
					score += 1
					continue
				}

				dirs := [?]Dir { cand.dir, dir_left(cand.dir), dir_right(cand.dir) }
				scores := [?]u32 { score, score + 1000, score + 1000 }
				steps := [?]int { fwd_step, -right_step, right_step }

				for path in soa_zip(dir = dirs[:], score = scores[:], step = steps[:]) {
					if path.score < best[pos][path.dir] {
						best[pos][path.dir] = path.score
						prev[pos][path.dir] = {}
					}

					if path.score == best[pos][path.dir] {
						assert(prev[pos][cand.dir][cand.dir] == 0 || prev[pos][cand.dir][cand.dir] == cand.index)
						prev[pos][path.dir][cand.dir] = cand.index

						if input[pos + path.step] != '#' {
							pq.push(&candidates, Candidate { index = u32(pos), dir = path.dir, score = path.score })
						}
					}
				}

			case '#', 'S':
			case: panic("bad cell")
			}

			break
		}
	}

	marked : ba.Bit_Array
	defer ba.destroy(&marked)
	ba.init(&marked, len(input))

	Segment :: struct { from, to: u32 }

	next : queue.Queue(Segment)
	defer queue.destroy(&next)

	end_index := int(metrics.end.x) + int(metrics.end.y) * stride
	for b, dir in best[end_index] {
		if b != u32(p1) do continue
		for p in prev[end_index][dir] {
			if p != 0 do queue.push_back(&next, Segment { from = u32(end_index), to = p })
		}
	}

	for segment in queue.pop_front_safe(&next) {
		dir : Dir
		step : int

		di := int(segment.from) - int(segment.to)
		switch {
		case di <= -stride: dir, step = .N, -stride
		case di <  0:       dir, step = .W, -1
		case di <  stride:  dir, step = .E, +1
		case:               dir, step = .S, +stride
		}
		assert(di % step == 0)

		for p in prev[segment.to][dir] {
			if p == 0 do continue
			queue.push_back(&next, Segment { from = segment.to, to = p })
		}

		for i := int(segment.from);; i -= step {
			if !ba.get(&marked, i) {
				ba.set(&marked, i)
				p2 += 1
			}

			if i == int(segment.to) do break
		}
	}

	/*
	for y in 0..<int(metrics.size.y) {
		for x in 0..<int(metrics.size.x) {
			i := x + y * stride
			if input[i] == '.' && ba.get(&marked, i) do fmt.print('O')
			else do fmt.print(rune(input[i]))
		}
		fmt.println()
	}
	*/

	return
}

DAY16_EXAMPLE1 ::
`###############
#.......#....E#
#.#.###.#.###.#
#.....#.#...#.#
#.###.#####.#.#
#.#.#.......#.#
#.#.#####.###.#
#...........#.#
###.#.#####.#.#
#...#.....#.#.#
#.#.#.###.#.#.#
#.....#...#.#.#
#.###.#.#.#.#.#
#S..#.....#...#
###############`

DAY16_EXAMPLE2 ::
`#################
#...#...#...#..E#
#.#.#.#.#.#.#.#.#
#.#.#.#...#...#.#
#.#.#.#.###.#.#.#
#...#.#.#.....#.#
#.#.#.#.#.#####.#
#.#...#.#.#.....#
#.#.#####.#.###.#
#.#.#.......#...#
#.#.###.#####.###
#.#.#...#.....#.#
#.#.#.#####.###.#
#.#.#.........#.#
#.#.#.#########.#
#S#.............#
#################`

@test
day16_test :: proc (t: ^testing.T) {
	input, input_err := day16_parse(DAY16_EXAMPLE1)
	testing.expect_value(t, input_err, nil)
	testing.expect_value(t, input.size.x, 15)
	testing.expect_value(t, input.size.y, 15)
	testing.expect_value(t, input.start, [2]u16 { 1, 13 })
	testing.expect_value(t, input.end, [2]u16 { 13, 1 })

	p1, p2 := day16_solve(DAY16_EXAMPLE1, input)
	testing.expect_value(t, p1, 7036)
	testing.expect_value(t, p2, 45)

	input, input_err = day16_parse(DAY16_EXAMPLE2)
	testing.expect_value(t, input_err, nil)
	testing.expect_value(t, input.size.x, 17)
	testing.expect_value(t, input.size.y, 17)
	testing.expect_value(t, input.start, [2]u16 { 1, 15 })
	testing.expect_value(t, input.end, [2]u16 { 15, 1 })

	p1, p2 = day16_solve(DAY16_EXAMPLE2, input)
	testing.expect_value(t, p1, 11048)
	testing.expect_value(t, p2, 64)
}

