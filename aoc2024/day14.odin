package aoc2024

import "core:fmt"
import "core:math/bits"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

Day14_Robot :: struct {
	px, py: u8,
	vx, vy: i8,
}

Day14_Input_Error :: enum {
	Ok,
	Invalid_Format,
	Invalid_Number,
}

day14 :: proc (input: string) {
	t := time.tick_now()

	robots, input_err := day14_parse(input)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day14_part1(robots[:], {101, 103}, 100)
	p1_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
}

day14_parse :: proc (input: string) -> (result: #soa[dynamic]Day14_Robot, err: Day14_Input_Error) {
	robots : #soa[dynamic]Day14_Robot
	defer if result == nil do delete(robots)

	left := input
	for len(left) > 0 {
		px, py : uint
		vx, vy, i : int
		robot : Day14_Robot

		assert(strings.has_prefix(left, "p="))
		left = left[2:]
		px, _ = strconv.parse_uint(left, 10, &i)
		if i == 0 do return nil, .Invalid_Format
		if px > uint(max(u8)) do return nil, .Invalid_Number

		assert(strings.has_prefix(left[i:], ","))
		left = left[i+1:]
		py, _ = strconv.parse_uint(left, 10, &i)
		if i == 0 do return nil, .Invalid_Format
		if px > uint(max(u8)) do return nil, .Invalid_Number

		assert(strings.has_prefix(left[i:], " v="))
		left = left[i+3:]
		vx, _ = strconv.parse_int(left, 10, &i)
		if i == 0 do return nil, .Invalid_Format
		if vx < int(min(i8)) || vx > int(max(i8)) do return nil, .Invalid_Number

		assert(strings.has_prefix(left[i:], ","))
		left = left[i+1:]
		vy, _ = strconv.parse_int(left, 10, &i)
		if i == 0 do return nil, .Invalid_Format
		if vy < int(min(i8)) || vy > int(max(i8)) do return nil, .Invalid_Number

		left = strings.trim_left_space(left[i:])
		append(&robots, Day14_Robot { u8(px), u8(py), i8(vx), i8(vy) })
	}

	return robots, nil
}

day14_part1 :: proc (robots: #soa[]Day14_Robot, grid_size: [2]int, duration: int) -> int {
	na, nb, nc, nd : int

	for robot in robots {
		dx, dy, fx, fy : int
		overflow : bool

		dx, overflow = bits.overflowing_mul(duration, int(robot.vx))
		assert(!overflow)
		dy, overflow = bits.overflowing_mul(duration, int(robot.vy))
		assert(!overflow)
		fx, overflow = bits.overflowing_add(dx, int(robot.px))
		assert(!overflow)
		fy, overflow = bits.overflowing_add(dy, int(robot.py))
		assert(!overflow)

		fx = (fx % grid_size.x + grid_size.x) % grid_size.x
		fy = (fy % grid_size.y + grid_size.y) % grid_size.y

		center := grid_size / 2
		switch {
		case fx < center.x && fy < center.y: na += 1
		case fx < center.x && fy > center.y: nb += 1
		case fx > center.x && fy < center.y: nc += 1
		case fx > center.x && fy > center.y: nd += 1
		}
	}

	return na * nb * nc * nd
}

DAY14_EXAMPLE ::
`p=0,4 v=3,-3
p=6,3 v=-1,-3
p=10,3 v=-1,2
p=2,0 v=2,-1
p=0,0 v=1,3
p=3,0 v=-2,-2
p=7,6 v=-1,-3
p=3,0 v=-1,-2
p=9,3 v=2,3
p=7,3 v=-1,2
p=2,4 v=2,-3
p=9,5 v=-3,-3`

@test
day14_example :: proc (t: ^testing.T) {
	robots, ok := day14_parse(DAY14_EXAMPLE)
	defer delete(robots)
	testing.expect_value(t, ok, nil)

	p1 := day14_part1(robots[:], {11, 7}, 100)
	testing.expect_value(t, p1, 12)
}

