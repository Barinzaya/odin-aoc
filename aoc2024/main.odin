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
	case 7: day7(input)
	case 8: day8(input)
	case 9: day9(input)
	case 10: day10(input)
	case 11: day11(input)
	case 12: day12(input)
	case 13: day13(input)
	case 14: day14(input)
	case 15: day15(input)
	case 16: day16(input)
	case 17: day17(input)
	case 18: day18(input)
	case 19: day19(input)
	case 20: day20(input)

	case:
		fmt.eprintln("Unknown day:", day)
		os.exit(1)
	}
}

