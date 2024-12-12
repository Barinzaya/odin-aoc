package day12_clusters

import "core:fmt"

main :: proc () {
	Neighbor :: enum u8 { N, NE, E, SE, S, SW, W, NW }

	iterate_clusters :: #force_inline proc (state: ^u16, same, different: bit_set[Neighbor; u16]) -> (result: u8, ok: bool) {
		assert(same & different == {})
		different  := transmute(u16)different
		same := transmute(u16)same

		skip := same | different
		assert(state^ & skip == 0)

		if state^ < 1 << len(Neighbor) {
			result = cast(u8)(state^ | same)
			ok = true
			state^ = (state^ | skip + 1) &~ skip
		} else {
			state^ = 0
		}

		return
	}

	cluster_scores : [256]u8
	state : u16

	// edges--+1 fence
	for n in iterate_clusters(&state, {}, {.N}) do cluster_scores[transmute(u8)n] += 0x01
	for n in iterate_clusters(&state, {}, {.S}) do cluster_scores[transmute(u8)n] += 0x01
	for n in iterate_clusters(&state, {}, {.E}) do cluster_scores[transmute(u8)n] += 0x01
	for n in iterate_clusters(&state, {}, {.W}) do cluster_scores[transmute(u8)n] += 0x01

	// inside corners--+1 side
	for n in iterate_clusters(&state, {.N, .E}, {.NE}) do cluster_scores[transmute(u8)n] += 0x10
	for n in iterate_clusters(&state, {.S, .E}, {.SE}) do cluster_scores[transmute(u8)n] += 0x10
	for n in iterate_clusters(&state, {.S, .W}, {.SW}) do cluster_scores[transmute(u8)n] += 0x10
	for n in iterate_clusters(&state, {.N, .W}, {.NW}) do cluster_scores[transmute(u8)n] += 0x10

	// outside corners--+1 side
	for n in iterate_clusters(&state, {}, {.N, .E}) do cluster_scores[transmute(u8)n] += 0x10
	for n in iterate_clusters(&state, {}, {.S, .E}) do cluster_scores[transmute(u8)n] += 0x10
	for n in iterate_clusters(&state, {}, {.S, .W}) do cluster_scores[transmute(u8)n] += 0x10
	for n in iterate_clusters(&state, {}, {.N, .W}) do cluster_scores[transmute(u8)n] += 0x10

	for score, i in cluster_scores {
		fmt.printf("0x%2x, ", score)
		if i % 16 == 15 do fmt.println()
	}
}

