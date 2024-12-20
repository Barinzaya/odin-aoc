package aoc2024

import ba "core:container/bit_array"
import pq "core:container/priority_queue"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:testing"
import "core:time"

Day18_Input_Error :: enum {
	Ok,
	Invalid_Format,
	Invalid_Position,
}

day18 :: proc (input: string) {
	t := time.tick_now()

	bytes, err := day18_parse(input, 71)
	defer delete(bytes)
	if err != nil {
		fmt.eprintln("Failed to parse input:", err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day18_part1(bytes[:1024], 71)
	p1_dur := time.tick_lap_time(&t)

	p2 := day18_part2(bytes, 71)
	p2_dur := time.tick_lap_time(&t)

	p2_byte := bytes[p2]
	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2: ", p2_byte.x, ",", p2_byte.y, " in ", p2_dur, sep="")
}

day18_parse :: proc (input: string, size: int) -> (result: [][2]u8, err: Day18_Input_Error) {
	number :: proc (s: string, max: int) -> (string, int, Day18_Input_Error) {
		i : int
		x, _ := strconv.parse_int(s, 10, &i)
		if i == 0 do return s, 0, .Invalid_Position
		if x < 0 || x >= max do return s, x, .Invalid_Position
		return s[i:], x, nil
	}

	text :: proc (s, prefix: string) -> (string, Day18_Input_Error) {
		n := len(prefix)
		if n <= len(s) && s[:n] == prefix {
			return s[n:], nil
		} else {
			return s, .Invalid_Format
		}
	}

	bytes : [dynamic][2]u8
	defer if err != nil do delete(bytes)

	left := input
	for {
		x, y : int
		left, x = number(left, size) or_break
		left = text(left, ",") or_return
		left, y = number(left, size) or_return
		left = text(left, "\n") or_break

		append(&bytes, [2]u8 { u8(x), u8(y) })
	}

	if len(left) > 0 do err = .Invalid_Position
	return bytes[:], nil
}

day18_part1 :: proc (bytes: [][2]u8, size: int) -> (result: int) {
	blocked : ba.Bit_Array
	ba.init(&blocked, size*size)
	defer ba.destroy(&blocked)

	for b in bytes {
		i := int(b.x) + int(b.y) * size
		ba.unsafe_set(&blocked, i)
	}

	return day18_solve(&blocked, size)
}

day18_part2 :: proc (bytes: [][2]u8, size: int) -> (result: int) {
	lo, hi := 0, len(bytes)-1
	last := 0

	blocked : ba.Bit_Array
	ba.init(&blocked, size*size)
	defer ba.destroy(&blocked)

	for lo <= hi {
		mid := (lo + hi) / 2

		switch {
		case last < mid: for b in bytes[last:mid+1] do ba.unsafe_set(&blocked, int(b.x) + int(b.y) * size)
		case mid < last: for b in bytes[mid:last+1] do ba.unsafe_unset(&blocked, int(b.x) + int(b.y) * size)
		}

		last = mid

		if day18_solve(&blocked, size) < 0 do hi = mid-1
		else do lo = mid+1
	}

	return lo
}

day18_solve :: proc (blocked: ^ba.Bit_Array, size: int) -> (result: int) {
	Candidate :: struct { x, y: u8, steps, est: u16 }
	assert(size <= 256)

	candidate_less :: proc (a, b: Candidate) -> bool { return a.est < b.est }
	candidate_swap :: proc (s: []Candidate, i, j: int) { s[i], s[j] = s[j], s[i] }

	best := make([]u16, size*size)
	defer delete(best)
	for &b in best do b = max(u16)

	candidates : pq.Priority_Queue(Candidate)
	pq.init(&candidates, candidate_less, candidate_swap)
	defer pq.destroy(&candidates)

	pq.push(&candidates, Candidate {
		x = 0, y = 0,
		steps = 0,
		est = u16(2*size - 2),
	})

	@(static,rodata)
	neighbors := [4][2]i8 { {0,-1}, {+1,0}, {0,+1}, {-1,0} }

	for candidate in pq.pop_safe(&candidates) {
		for n in neighbors {
			nx, ny := candidate.x + u8(n.x), candidate.y + u8(n.y)
			if int(nx) >= size || int(ny) >= size do continue

			i := int(nx) + int(ny) * size
			if ba.unsafe_get(blocked, i) do continue

			steps := candidate.steps + 1
			if best[i] <= steps do continue
			best[i] = steps

			dist := 2*size - 2 - int(nx) - int(ny)
			if dist == 0 do return int(steps)

			pq.push(&candidates, Candidate {
				x = nx, y = ny,
				steps = steps,
				est = steps + u16(dist),
			})
		}
	}

	return -1
}

DAY18_EXAMPLE ::
`5,4
4,2
4,5
3,0
2,1
6,3
2,4
1,5
0,6
3,3
2,6
5,1
1,2
5,5
2,5
6,5
1,4
0,4
6,4
1,1
6,1
1,0
0,5
1,6
2,0`

@test
day18_test :: proc (t: ^testing.T) {
	bytes, err := day18_parse(DAY18_EXAMPLE, 7)
	defer delete(bytes)
	testing.expect_value(t, err, nil)

	p1 := day18_part1(bytes[:12], 7)
	testing.expect_value(t, p1, 22)

	p2 := day18_part2(bytes, 7)
	testing.expect_value(t, bytes[p2], [2]u8 { 6, 1 })
}

