package aoc2024

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

Day17_Input_Error :: enum {
	Ok,
	Invalid_Format,
	Invalid_Value,
}

Day17_Register :: enum u8 { A, B, C }

Day17_VM :: struct {
	reg: [Day17_Register]u64,
	code: []u8,
}

day17 :: proc (input: string) {
	t := time.tick_now()

	vm, err := day17_parse(input)
	if err != nil {
		fmt.eprintln("Failed to parse input:", err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day17_part1(vm)
	defer delete(p1)
	p1_dur := time.tick_lap_time(&t)

	p2 := day17_part2(vm)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2:", p2, "in", p2_dur)
}

day17_parse :: proc (input: string) -> (vm: Day17_VM, err: Day17_Input_Error) {
	number :: proc (s: string) -> (string, u64, Day17_Input_Error) {
		i : int
		x, _ := strconv.parse_u64(s, 10, &i)
		if i == 0 do return s, 0, .Invalid_Value
		return s[i:], x, nil
	}

	text :: proc (s, prefix: string) -> (string, Day17_Input_Error) {
		n := len(prefix)
		if n <= len(s) && s[:n] == prefix {
			return s[n:], nil
		} else {
			return s, .Invalid_Format
		}
	}

	left := input
	left = text(left, "Register A: ") or_return
	left, vm.reg[.A] = number(left) or_return
	left = text(left, "\nRegister B: ") or_return
	left, vm.reg[.B] = number(left) or_return
	left = text(left, "\nRegister C: ") or_return
	left, vm.reg[.C] = number(left) or_return
	left = text(left, "\n\nProgram: ") or_return

	code : [dynamic]u8
	defer if vm.code == nil do delete(code)

	x : u64
	for {
		left, x = number(left) or_return
		if x < 0 || x > 7 do return vm, .Invalid_Value
		append(&code, u8(x))

		left = text(left, ",") or_break
	}

	vm.code = code[:]
	return
}

day17_read_combo :: proc (vm: ^Day17_VM, operand: u8) -> u64 {
	switch operand {
	case 0..=3: return u64(operand)
	case 4: return vm.reg[.A]
	case 5: return vm.reg[.B]
	case 6: return vm.reg[.C]
	case 7: panic("Undefined combo literal")

	case: panic("Invalid operand")
	}
}

day17_part1 :: proc (vm: Day17_VM) -> string {
	out : [dynamic]u8
	defer delete(out)

	vm := vm
	day17_run(&vm, &out)

	s : strings.Builder
	if len(out) > 0 {
		strings.builder_init(&s, 0, 2*len(out) - 1)
		for x, i in out do fmt.sbprintf(&s, ",%v" if i > 0 else "%v", x)
	}

	return strings.to_string(s)
}

day17_part2 :: proc (vm: Day17_VM) -> u64 {
	cand_old, cand_new : [dynamic]u64
	defer delete(cand_old)
	defer delete(cand_new)
	append(&cand_old, 0)

	out : [dynamic]u8
	defer delete(out)

	n := len(vm.code)
	assert(vm.code[n-2] == 3)
	assert(vm.code[n-1] == 0)
	trial_vm := Day17_VM { code = vm.code[:n-2] }

	#reverse for x in vm.code {
		// Assumes input is a loop that executes ADV 3 each time
		for cand in cand_old {
			for t in u64(0)..<8 {
				trial := cand << 3 + t
				trial_vm.reg[.A] = trial

				clear(&out)
				day17_run(&trial_vm, &out)
				assert(len(out) == 1)

				if x == out[0] {
					append(&cand_new, trial)
				}
			}
		}

		clear(&cand_old)
		cand_old, cand_new = cand_new, cand_old
	}

	assert(len(cand_old) > 0)
	return cand_old[0]
}

day17_run :: proc (vm: ^Day17_VM, out: ^[dynamic]u8) {
	pc : u64
	for pc < u64(len(vm.code)) {
		opcode := vm.code[pc]
		operand := vm.code[pc+1]
		pc += 2

		switch opcode {
		case 0: vm.reg[.A] >>= uint(day17_read_combo(vm, operand))
		case 1: vm.reg[.B] ~= u64(operand)
		case 2: vm.reg[.B] = day17_read_combo(vm, operand) & 0x7
		case 3: if vm.reg[.A] != 0 do pc = u64(operand)
		case 4: vm.reg[.B] ~= vm.reg[.C]
		case 5: append(out, u8(day17_read_combo(vm, operand)) & 0x7)
		case 6: vm.reg[.B] = vm.reg[.A] >> uint(day17_read_combo(vm, operand))
		case 7: vm.reg[.C] = vm.reg[.A] >> uint(day17_read_combo(vm, operand))

		case: panic("Invalid instruction")
		}
	}
}

DAY17_EXAMPLE1 ::
`Register A: 729
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0`

DAY17_EXAMPLE2 ::
`Register A: 2024
Register B: 0
Register C: 0

Program: 0,3,5,4,3,0`

@test
day17_test :: proc (t: ^testing.T) {
	out : [dynamic]u8
	defer delete(out)
	vm : Day17_VM

	clear(&out)
	vm = {reg = {.A = 0, .B = 0, .C = 9}, code = {2, 6}}
	day17_run(&vm, &out)
	testing.expect_value(t, vm.reg, [Day17_Register]u64 {.A = 0, .B = 1, .C = 9})
	testing.expect(t, slice.equal(out[:], []u8 {}))

	clear(&out)
	vm = {reg = {.A = 10, .B = 0, .C = 0}, code = {5,0,5,1,5,4}}
	day17_run(&vm, &out)
	testing.expect_value(t, vm.reg, [Day17_Register]u64 {.A = 10, .B = 0, .C = 0})
	testing.expect(t, slice.equal(out[:], []u8 {0, 1, 2}))

	clear(&out)
	vm = {reg = {.A = 2024, .B = 0, .C = 0}, code = {0,1,5,4,3,0}}
	day17_run(&vm, &out)
	testing.expect_value(t, vm.reg, [Day17_Register]u64 {.A = 0, .B = 0, .C = 0})
	testing.expect(t, slice.equal(out[:], []u8 {4,2,5,6,7,7,7,7,3,1,0}))

	clear(&out)
	vm = {reg = {.A = 0, .B = 29, .C = 0}, code = {1,7}}
	day17_run(&vm, &out)
	testing.expect_value(t, vm.reg, [Day17_Register]u64 {.A = 0, .B = 26, .C = 0})
	testing.expect(t, slice.equal(out[:], []u8 {}))

	clear(&out)
	vm = {reg = {.A = 0, .B = 2024, .C = 43690}, code = {4,0}}
	day17_run(&vm, &out)
	testing.expect_value(t, vm.reg, [Day17_Register]u64 {.A = 0, .B = 44354, .C = 43690})
	testing.expect(t, slice.equal(out[:], []u8 {}))
}

@test
day17_test_example1 :: proc (t: ^testing.T) {
	vm, err := day17_parse(DAY17_EXAMPLE1)
	defer delete(vm.code)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, vm.reg[.A], 729)
	testing.expect_value(t, vm.reg[.B], 0)
	testing.expect_value(t, vm.reg[.C], 0)
	testing.expect(t, slice.equal(vm.code, []u8 {0, 1, 5, 4, 3, 0}))

	out := day17_part1(vm)
	defer delete(out)
	testing.expect_value(t, out, "4,6,3,5,6,3,5,2,1,0")
}

//@test
day17_test_example2 :: proc (t: ^testing.T) {
	vm, err := day17_parse(DAY17_EXAMPLE2)
	defer delete(vm.code)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, vm.reg[.A], 2024)
	testing.expect_value(t, vm.reg[.B], 0)
	testing.expect_value(t, vm.reg[.C], 0)
	testing.expect(t, slice.equal(vm.code, []u8 {0, 3, 5, 4, 3, 0}))

	p2 := day17_part2(vm)
	testing.expect_value(t, p2, 117440)
}

