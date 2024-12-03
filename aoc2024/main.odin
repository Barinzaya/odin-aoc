package aoc2024

import "core:fmt"
import "core:os"

run :: proc (day: int, input: string) {
	switch day {
	case 1: day1(input)
	case 2: day2(input)
	case:
		fmt.eprintln("Unknown day:", day)
		os.exit(1)
	}
}

