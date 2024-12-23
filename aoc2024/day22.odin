package aoc2024

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

day22 :: proc (input: string) {
	t := time.tick_now()

	secrets, ok := day22_parse(input, context.temp_allocator)
	if !ok {
		fmt.eprintln("Failed to parse input!")
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day22_part1(secrets)
	p1_dur := time.tick_lap_time(&t)

	p2 := day22_part2(secrets)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day22_parse :: proc (input: string, allocator := context.allocator) -> (result: []u32, ok: bool) {
	secrets := make([dynamic]u32, allocator)
	defer if !ok do delete(secrets)

	left := input
	for line in strings.split_lines_iterator(&left) {
		if len(line) == 0 do continue
		x := strconv.parse_uint(line, 10, nil) or_return
		append(&secrets, u32(x))
	}

	return secrets[:], true
}

day22_part1 :: proc (secrets: []u32, iterations := 2000) -> (result: u64) {
	for secret in secrets {
		MASK :: 1 << 24 - 1
		secret := secret

		for _ in 0..<iterations do secret = day22_step(secret)
		result += u64(secret)
	}
	return
}

day22_part2 :: proc (secrets: []u32, iterations := 2000) -> (result: u64) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	Slot :: struct {
		next, sum: u32,
	}
	slots := make([]Slot, 19*19*19*19, context.temp_allocator)

	for secret, i in secrets {
		changes : u32
		secret := secret
		price := secret % 10

		for j in 0..<iterations {
			secret = day22_step(secret)

			new_price := secret % 10
			changes = changes % (19*19*19) * 19 + (new_price - price + 9)
			price = new_price

			if j >= 3 && int(slots[changes].next) <= i {
				slots[changes].next = u32(i + 1)
				slots[changes].sum += price
			}
		}
	}

	for slot, c in slots do result = max(result, u64(slot.sum))
	return
}

day22_step :: proc (secret: u32) -> u32 {
	MASK :: 1 << 24 - 1
	secret := (secret ~ (secret << 6)) & MASK
	secret  = (secret ~ (secret >> 5))
	secret  = (secret ~ (secret << 11)) & MASK
	return secret
}

DAY22_EXAMPLE1 ::
`1
10
100
2024`

DAY22_EXAMPLE2 ::
`1
2
3
2024`

@test
day22_test :: proc (t: ^testing.T) {
	testing.expect_value(t, day22_part1({123},  1), 15887950)
	testing.expect_value(t, day22_part1({123},  2), 16495136)
	testing.expect_value(t, day22_part1({123},  3), 527345)
	testing.expect_value(t, day22_part1({123},  4), 704524)
	testing.expect_value(t, day22_part1({123},  5), 1553684)
	testing.expect_value(t, day22_part1({123},  6), 12683156)
	testing.expect_value(t, day22_part1({123},  7), 11100544)
	testing.expect_value(t, day22_part1({123},  8), 12249484)
	testing.expect_value(t, day22_part1({123},  9), 7753432)
	testing.expect_value(t, day22_part1({123}, 10), 5908254)

	secrets1, ok1 := day22_parse(DAY22_EXAMPLE1, context.temp_allocator)
	testing.expect(t, ok1)

	p1 := day22_part1(secrets1)
	testing.expect_value(t, p1, 37327623)

	secrets2, ok2 := day22_parse(DAY22_EXAMPLE2, context.temp_allocator)
	testing.expect(t, ok2)

	p2 := day22_part2(secrets2)
	testing.expect_value(t, p2, 23)
}

