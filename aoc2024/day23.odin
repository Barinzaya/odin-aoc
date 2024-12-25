package aoc2024

import "base:runtime"
import ba "core:container/bit_array"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"
import "core:time"

Day23_Input_Error :: enum {
	Ok,
	Invalid_Computer,
	Invalid_Token,
	Unexpected_End,
}

Day23_Pair :: struct {
	a, b : [2]u8,
}

day23 :: proc (input: string) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	t := time.tick_now()

	pairs, err := day23_parse(input, context.temp_allocator)
	if err != nil {
		fmt.eprintln("Failed to parse input:", err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	slice.sort_by_cmp(pairs, day23_pair_cmp)
	sort_dur := time.tick_lap_time(&t)

	p1 := day23_part1(pairs)
	p1_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Sorted input in", sort_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
}

day23_parse :: proc (input: string, allocator := context.allocator) -> (result: []Day23_Pair, err: Day23_Input_Error) {
	read_computer :: proc (left: ^string) -> (computer: [2]u8, err: Day23_Input_Error) {
		if len(left^) < 2 do return {}, .Unexpected_End
		computer[0] = left[0] - 'a'
		if computer[0] >= 26 do return {}, .Invalid_Computer
		computer[1] = left[1] - 'a'
		if computer[1] >= 26 do return {}, .Invalid_Computer
		left^ = left[2:]
		return
	}

	skip_token :: proc (left: ^string, token: string) -> Day23_Input_Error {
		n := len(token)
		if len(left^) < n do return .Unexpected_End
		if left[:n] != token do return .Invalid_Token
		left^ = left[n:]
		return .Ok
	}

	pairs := make([dynamic]Day23_Pair, allocator)
	defer if err != nil do delete(pairs)

	left := input
	for len(left) > 0 {
		a := read_computer(&left) or_return
		skip_token(&left, "-") or_return
		b := read_computer(&left) or_return
		if len(left) > 0 do skip_token(&left, "\n") or_return
		if day23_computer_cmp(a, b) == .Greater do a, b = b, a
		append(&pairs, Day23_Pair { a, b })
	}

	result = pairs[:]
	return
}

day23_part1 :: proc (pairs: []Day23_Pair) -> (result: u64) {
	for pair, i in pairs {
		for other, j in pairs[i+1:] {
			if pair.a != other.a do break

			prefix := u8('t' - 'a')
			if pair.a[0] != prefix && pair.b[0] != prefix && other.b[0] != prefix do continue

			_ = slice.binary_search_by(pairs, Day23_Pair {pair.b, other.b}, day23_pair_cmp) or_continue
			result += 1
		}
	}

	return
}

day23_part2 :: proc (named_pairs: []Day23_Pair) -> string {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	Pair :: struct { a, b: u16 }
	pair_cmp :: proc (a, b: Pair) -> slice.Ordering { 
		slice.cmp(a.a, b.a) or_return
		slice.cmp(a.b, b.b) or_return
		return .Equal
	}

	names := make([dynamic][2]u8, 0, len(named_pairs), context.temp_allocator)
	pairs := make([]Pair, len(named_pairs), context.temp_allocator)

	for pair, i in named_pairs {
		a, a_ok := slice.binary_search_by(names[:], pair.a, day23_computer_cmp)
		if !a_ok {
			assert(len(names) <= int(max(u16)))
			a = len(names)
			append(&names, pair.a)
		}

		b, b_ok := slice.binary_search_by(names[:], pair.b, day23_computer_cmp)
		if !b_ok {
			assert(len(names) <= int(max(u16)))
			b = len(names)
			append(&names, pair.b)
		}

		pairs[i] = {u16(a), u16(b)}
	}

	num_best, num_current : int
	best, candidates, current : ba.Bit_Array

	ba.init(&best, len(names), allocator = context.temp_allocator)
	ba.init(&candidates, len(names), allocator = context.temp_allocator)
	ba.init(&current, len(names), allocator = context.temp_allocator)

	recurse :: proc (num_best, num_current: ^int, best, candidates, current: ^ba.Bit_Array, pairs: []Pair) {
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

		if num_best^ < num_current^ {
			num_best^ = num_current^
			copy(best.bits[:], current.bits[:])
		}

		new_candidates, remaining : ba.Bit_Array
		ba.init(&new_candidates, ba.len(candidates), allocator = context.temp_allocator)
		ba.init(&remaining,      ba.len(candidates), allocator = context.temp_allocator)
		copy(remaining.bits[:], candidates.bits[:])

		iter := ba.make_iterator(&remaining)
		for next in ba.iterate_by_set(&iter) {
			ba.unsafe_unset(&remaining, next)

			start, _ := slice.binary_search_by(pairs, Pair { u16(next), 0 }, pair_cmp)
			ba.clear(&new_candidates)

			for pair in pairs[start:] {
				if pair.a != u16(next) do break
				ba.unsafe_set(&new_candidates, int(pair.b))
			}

			for &x in soa_zip(new = new_candidates.bits[:], old = candidates.bits[:]) {
				x.new &= x.old
			}

			ba.unsafe_set(current, next)
			num_current^ += 1

			recurse(num_best, num_current, best, &new_candidates, current, pairs)

			ba.unsafe_unset(current, next)
			num_current^ -= 1
		}
	}

	for i := 0; i < len(pairs); i += 1 {
		name := pairs[i].a
		for /**/; i < len(pairs); i += 1 {
			pair := pairs[i]
			if pair.a != name do break
			ba.unsafe_set(&candidates, int(pair.b))
		}

		ba.unsafe_set(&current, int(name))
		num_current = 1

		recurse(&num_best, &num_current, &best, &candidates, &current, pairs)

		assert(num_current == 1)
		ba.unsafe_unset(&current, int(name))

		ba.clear(&candidates)
	}

	fmt.println("BEST:", num_best)
	return ""
}

day23_computer_cmp :: proc (a, b: [2]u8) -> slice.Ordering { 
	slice.cmp(a[0], b[0]) or_return
	slice.cmp(a[1], b[1]) or_return
	return .Equal
}

day23_pair_cmp :: proc (a, b: Day23_Pair) -> slice.Ordering { 
	day23_computer_cmp(a.a, b.a) or_return
	day23_computer_cmp(a.b, b.b) or_return
	return .Equal
}

DAY23_EXAMPLE ::
`kh-tc
qp-kh
de-cg
ka-co
yn-aq
qp-ub
cg-tb
vc-aq
tb-ka
wh-tc
yn-cg
kh-ub
ta-co
de-co
tc-td
tb-wq
wh-td
ta-ka
td-qp
aq-cg
wq-ub
ub-vc
de-ta
wq-aq
wq-vc
wh-yn
ka-de
kh-ta
co-tc
wh-qp
tb-vc
td-yn`

@test
day23_test :: proc (t: ^testing.T) {
	pairs, err := day23_parse(DAY23_EXAMPLE, context.temp_allocator)
	testing.expect_value(t, err, nil)

	testing.expect_value(t, len(pairs), 32)
	testing.expect_value(t, pairs[0], Day23_Pair {cast([2]u8)"kh" - 'a', cast([2]u8)"tc" - 'a'})
	testing.expect_value(t, pairs[1], Day23_Pair {cast([2]u8)"kh" - 'a', cast([2]u8)"qp" - 'a'})

	slice.sort_by_cmp(pairs, day23_pair_cmp)

	p1 := day23_part1(pairs)
	testing.expect_value(t, p1, 7)

	p2 := day23_part2(pairs)
	defer delete(p2)
	testing.expect_value(t, p2, "co,de,ka,ta")
}

