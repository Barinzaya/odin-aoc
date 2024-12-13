package aoc2024

import "core:fmt"
import "core:math/linalg"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

Day13_Input_Error :: enum {
	Ok,
	Bad_Format,
	Invalid_Number,
}

Day13_Machine :: struct {
	a, b, target: [2]int,
}

day13 :: proc (input: string) {
	t := time.tick_now()

	machines, input_err := day13_parse(input)
	if input_err != nil {
		fmt.eprintln("Failed to parse input:", input_err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day13_solve(machines[:])
	p1_dur := time.tick_lap_time(&t)
	p2 := day13_solve(machines[:], 10000000000000)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day13_parse :: proc (input: string) -> (result: [dynamic]Day13_Machine, err: Day13_Input_Error) {
	machines := make([dynamic]Day13_Machine)
	defer if err != nil do delete(machines)

	number :: proc (s: string) -> (string, int, Day13_Input_Error) {
		i : int
		x, _ := strconv.parse_int(s, 10, &i)
		if i == 0 do return "", 0, .Invalid_Number
		return s[i:], x, nil
	}

	text :: proc (s, prefix: string) -> (string, Day13_Input_Error) {
		n := len(prefix)
		if n <= len(s) && s[:n] == prefix {
			return s[n:], nil
		} else {
			return s, .Bad_Format
		}
	}

	left := input
	for len(left) > 0 {
		ax, ay, bx, by, tx, ty : int

		left = text(left, "Button A: X+") or_return
		left, ax = number(left) or_return
		left = text(left, ", Y+") or_return
		left, ay = number(left) or_return
		left = text(left, "\nButton B: X+") or_return
		left, bx = number(left) or_return
		left = text(left, ", Y+") or_return
		left, by = number(left) or_return
		left = text(left, "\nPrize: X=") or_return
		left, tx = number(left) or_return
		left = text(left, ", Y=") or_return
		left, ty = number(left) or_return
		left = strings.trim_left_space(left)

		append(&machines, Day13_Machine {
			a = {ax, ay}, b = {bx, by}, target = {tx, ty},
		})
	}

	result = machines
	return
}

day13_solve :: proc (machines: []Day13_Machine, extra : int = 0) -> (result: int) {
	for machine in machines {
		a, b, t := expand_values(machine)
		t += extra

		// Cramer's rule
		a_num := linalg.determinant(matrix[2,2]int {
			t.x, b.x,
			t.y, b.y,
		})
		b_num := linalg.determinant(matrix[2,2]int {
			a.x, t.x,
			a.y, t.y,
		})
		denom := linalg.determinant(matrix[2,2]int {
			a.x, b.x,
			a.y, b.y,
		})

		if denom != 0 && a_num % denom == 0 && b_num % denom == 0 {
			num_a := a_num / denom
			num_b := b_num / denom
			result += 3*num_a + num_b
		}
	}

	return
}

DAY13_EXAMPLE ::
`Button A: X+94, Y+34
Button B: X+22, Y+67
Prize: X=8400, Y=5400

Button A: X+26, Y+66
Button B: X+67, Y+21
Prize: X=12748, Y=12176

Button A: X+17, Y+86
Button B: X+84, Y+37
Prize: X=7870, Y=6450

Button A: X+69, Y+23
Button B: X+27, Y+71
Prize: X=18641, Y=10279`

@test
test_day13 :: proc (t: ^testing.T) {
	machines, err := day13_parse(DAY13_EXAMPLE)
	defer delete(machines)
	testing.expect_value(t, err, nil)

	p1 := day13_solve(machines[:])
	testing.expect_value(t, p1, 480)
}

