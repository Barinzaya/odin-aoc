package aoc2024

import "base:runtime"
import "core:bufio"
import ts "core:container/topological_sort"
import "core:fmt"
import "core:io"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

Day24_Source :: union {
	Day24_Constant,
	Day24_Gate,
}

Day24_Constant :: struct { value: bool }
Day24_Gate :: struct { a, b: [3]u8, op: Day24_Operation }

Day24_Input_Error :: enum {
	Ok,
	Invalid_Name,
	Invalid_Value,
	Invalid_Format,
	Invalid_Operation,
	Unexpected_End,
}

Day24_Operation :: enum u8 {
	And,
	Or,
	Xor,
}

day24 :: proc (input: string) {
	t := time.tick_now()

	gates, err := day24_parse(input, context.temp_allocator)
	if err != nil {
		fmt.eprintln("Failed to parse input:", err)
		os.exit(1)
	}
	parse_dur := time.tick_lap_time(&t)

	p1 := day24_part1(gates)
	p1_dur := time.tick_lap_time(&t)

	day24_part2(gates)
	p2_dur := time.tick_lap_time(&t)

	fmt.println("Parsed input in", parse_dur)
	fmt.println("Part 1:", p1, "in", p1_dur)
	fmt.println("Part 2 graph generated in", p2_dur)
}

day24_part1 :: proc (gates: map[[3]u8]Day24_Source) -> (result: u64) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	cache := make(map[[3]u8]bool, len(gates), context.temp_allocator)
	out : [3]u8
	out[0] = 'z'

	for i in u8(0)..<64 {
		out[1] = '0' + i/10
		out[2] = '0' + i%10
		z := day24_evaluate(out, gates, &cache) or_break
		result |= u64(z) << i
	}

	return
}

day24_part2 :: proc (gates: map[[3]u8]Day24_Source) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	dot_handle, open_err := os.open("24.dot", os.O_CREATE | os.O_TRUNC | os.O_WRONLY)
	if open_err != nil {
		fmt.eprintln("Failed to open <24.dot>:", open_err)
		os.exit(1)
	}
	defer os.close(dot_handle)
	
	dot_buf : bufio.Writer
	bufio.writer_init(&dot_buf, os.stream_from_handle(dot_handle), allocator = context.temp_allocator)
	defer bufio.writer_destroy(&dot_buf)

	dot := bufio.writer_to_writer(&dot_buf)
	fmt.wprintfln(dot, `digraph {{`)

	for name, gate in gates {
		color, label : string

		switch g in gate {
		case Day24_Constant:
			color = "#bbf"
			label = "1\\n\\N" if g.value else "0\\n\\N"

		case Day24_Gate:
			name := name

			color = "#bbb"
			label = string(name[:])

			op : string
			switch g.op {
			case .And: op = "&"
			case .Or:  op = "|"
			case .Xor: op = "~"
			}

			fmt.wprintfln(dot, `  _op_%s [label="%s", fillcolor="#bbb", style="filled"]`, name, op)
			fmt.wprintfln(dot, `  %s -> _op_%s`, g.a, name)
			fmt.wprintfln(dot, `  %s -> _op_%s`, g.b, name)
			fmt.wprintfln(dot, `  _op_%s -> %s`, name, name)
		}

		if name[0] == 'z' do color = "#fdb"
		fmt.wprintfln(dot, `  %s [label="%s", fillcolor="%s", style="filled"]`, name, label, color)
	}

	fmt.wprintfln(dot, `}}`)
	return
}

day24_evaluate :: proc (name: [3]u8, gates: map[[3]u8]Day24_Source, cache: ^map[[3]u8]bool) -> (result: bool, ok: bool) {
	if result, ok = cache[name]; ok do return

	gate := gates[name] or_return
	switch g in gate {
	case Day24_Constant: result = g.value
	case Day24_Gate:
		a := day24_evaluate(g.a, gates, cache) or_return
		b := day24_evaluate(g.b, gates, cache) or_return
		switch g.op {
		case .And: result = a & b
		case .Or:  result = a | b
		case .Xor: result = a ~ b
		case: unreachable()
		}

	case: unreachable()
	}

	cache[name] = result
	ok = true
	return
}

day24_parse :: proc (input: string, allocator := context.allocator) -> (result: map[[3]u8]Day24_Source, err: Day24_Input_Error) {
	read_name :: proc (left: ^string) -> (result: [3]u8, err: Day24_Input_Error) {
		if len(left) < 3 do return {}, .Unexpected_End

		result = {left[0], left[1], left[2]}
		for c in result do switch c {
		case 'a'..='z', 'A'..='Z', '0'..='9':
		case: return result, .Invalid_Name
		}

		left^ = left[3:]
		return
	}

	read_op :: proc (left: ^string) -> (op: Day24_Operation, err: Day24_Input_Error) {
		switch {
		case strings.has_prefix(left^, "AND"):
			left^ = left[3:]
			op = .And

		case strings.has_prefix(left^, "OR"):
			left^ = left[2:]
			op = .Or

		case strings.has_prefix(left^, "XOR"):
			left^ = left[3:]
			op = .Xor

		case: err = .Invalid_Operation
		}
		return
	}

	read_value :: proc (left: ^string) -> (result: bool, err: Day24_Input_Error) {
		i : int
		x, _ := strconv.parse_int(left^, 10, &i)
		if i == 0 || x < 0 || x > 1 do err = .Invalid_Value
		left^ = left[i:]
		result = x > 0
		return
	}

	skip_token :: proc (left: ^string, token: string) -> Day24_Input_Error {
		n := len(token)
		if len(left) < n do return .Unexpected_End
		if left[:n] != token do return .Invalid_Format
		left^ = left[n:]
		return nil
	}

	gates := make(map[[3]u8]Day24_Source, allocator)
	defer if err != nil do delete(gates)

	left := input
	for len(left) > 0 {
		if skip_token(&left, "\n") == nil do break

		name := read_name(&left) or_return
		skip_token(&left, ": ") or_return
		value := read_value(&left) or_return
		skip_token(&left, "\n")

		gates[name] = Day24_Constant { value }
	}

	for len(left) > 0 {
		a := read_name(&left) or_return
		skip_token(&left, " ") or_return
		op := read_op(&left) or_return
		skip_token(&left, " ") or_return
		b := read_name(&left) or_return
		skip_token(&left, " -> ") or_return
		c := read_name(&left) or_return
		skip_token(&left, "\n")

		gates[c] = Day24_Gate { a, b, op }
	}

	result = gates
	return
}

DAY24_EXAMPLE1 ::
`x00: 1
x01: 1
x02: 1
y00: 0
y01: 1
y02: 0

x00 AND y00 -> z00
x01 XOR y01 -> z01
x02 OR y02 -> z02`

DAY24_EXAMPLE2 ::
`x00: 1
x01: 0
x02: 1
x03: 1
x04: 0
y00: 1
y01: 1
y02: 1
y03: 1
y04: 1

ntg XOR fgs -> mjb
y02 OR x01 -> tnw
kwq OR kpj -> z05
x00 OR x03 -> fst
tgd XOR rvg -> z01
vdt OR tnw -> bfw
bfw AND frj -> z10
ffh OR nrd -> bqk
y00 AND y03 -> djm
y03 OR y00 -> psh
bqk OR frj -> z08
tnw OR fst -> frj
gnj AND tgd -> z11
bfw XOR mjb -> z00
x03 OR x00 -> vdt
gnj AND wpb -> z02
x04 AND y00 -> kjc
djm OR pbm -> qhw
nrd AND vdt -> hwm
kjc AND fst -> rvg
y04 OR y02 -> fgs
y01 AND x02 -> pbm
ntg OR kjc -> kwq
psh XOR fgs -> tgd
qhw XOR tgd -> z09
pbm OR djm -> kpj
x03 XOR y03 -> ffh
x00 XOR y04 -> ntg
bfw OR bqk -> z06
nrd XOR fgs -> wpb
frj XOR qhw -> z04
bqk OR frj -> z07
y03 OR x01 -> nrd
hwm AND bqk -> z03
tgd XOR rvg -> z12
tnw OR pbm -> gnj`

@test
day24_test :: proc (t: ^testing.T) {
	d1, err1 := day24_parse(DAY24_EXAMPLE1, context.temp_allocator)
	testing.expect_value(t, err1, nil)

	p1 := day24_part1(d1)
	testing.expect_value(t, p1, 4)

	d2, err2 := day24_parse(DAY24_EXAMPLE2, context.temp_allocator)
	testing.expect_value(t, err2, nil)

	p1 = day24_part1(d2)
	testing.expect_value(t, p1, 2024)
}

