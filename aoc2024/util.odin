package aoc2024

import "core:math/bits"

ilog10_u64 :: proc (x: u64) -> u64 {
	@(static, rodata)
	limits := [20]u64 {
		1e0-1,  1e1-1,  1e2-1,  1e3-1,  1e4-1,  1e5-1,  1e6-1,  1e7-1,  1e8-1,  1e9-1,
		1e10-1, 1e11-1, 1e12-1, 1e13-1, 1e14-1, 1e15-1, 1e16-1, 1e17-1, 1e18-1, 1e19-1,
	}

	log10 := bits.log2(x) * 19 / 64
	log10 += u64(limits[log10 + 1] - x) >> 63
	return log10
}

