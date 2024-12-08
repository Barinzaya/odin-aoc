package aoc2024

import "core:fmt"
import "core:os"

run :: proc (day: int, input: string) {
	switch day {
	case 1: day1(input)
	case 2: day2(input)
	case 3: day3(input)
	case 4: day4(input)
	case 5: day5(input)
	case 6: day6(input)

	case:
		fmt.eprintln("Unknown day:", day)
		os.exit(1)
	}
}

