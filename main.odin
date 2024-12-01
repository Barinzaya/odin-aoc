package aoc

import "core:flags"
import "core:fmt"
import "core:mem/virtual"
import "core:os"

import "aoc2024"

Args :: struct {
	year: int `args:"pos=0,required"`,
	day: int `args:"pos=1,required"`,
	input: os.Handle `args:"pos=2,required,file=r"`,
}

main :: proc () {
	args : Args
	flags.parse_or_exit(&args, os.args)

	defer os.close(args.input)

	input_bytes, input_err := virtual.map_file(uintptr(args.input), { .Read })
	if input_err != nil {
		fmt.eprintln("Failed to open input file", input_err)
		os.exit(1)
	}
	defer virtual.release(raw_data(input_bytes), len(input_bytes))
	input := string(input_bytes)

	switch args.year {
	case 2024: aoc2024.run(args.day, input)
	case:
		fmt.eprintln("Unknown year:", args.year)
		os.exit(1)
	}
}

