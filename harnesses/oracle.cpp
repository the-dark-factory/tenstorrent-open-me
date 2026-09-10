// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: © 2026 The Dark Factory Ltd
// Calls the upstream library through its own headers; copies no upstream code.
// DIFFERENTIAL ORACLE — calls tt-npe's OWN code. Nothing here re-implements their
// arithmetic; every value printed comes from their headers/library.
#include "npeDependencyTracker.hpp"
#include "grid.hpp"
#include "npeUtil.hpp"
#include <cstdio>
#include <cstdint>

using namespace tt_npe;

// deterministic xorshift, so the run is reproducible
static uint64_t seed = 88172645463325252ULL;
static uint64_t nxt() { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }
static long long pick(long long lo, long long hi) {
    return lo + (long long)(nxt() % (uint64_t)(hi - lo + 1));
}

int main() {
    // ---- A: checkpoint ----------------------------------------------------
    for (int i = 0; i < 400; i++) {
        long long expected = pick(1, 8);
        long long arrived  = (pick(0,1) ? expected : pick(0, expected));
        long long finish   = pick(0, 20000);
        long long wait     = pick(0, 5000);
        // straddle the release point so done== both ways are exercised
        long long rel_guess = finish + wait;
        long long current  = (pick(0,1) ? rel_guess + pick(-3, 3) : pick(0, 40000));
        if (current < 0) current = 0;

        npeTransferDependencyTracker t;
        auto id = t.createCheckpoint((uint32_t)expected, (Cycle)wait);
        for (long long k = 0; k < arrived; k++) t.updateCheckpoint(id, (Cycle)finish);
        bool done = t.done(id, (Cycle)current);
        Cycle rel = t.end_cycle_plus_delay(id);
        bool all  = t.allComplete();
        std::printf("A,%lld,%lld,%lld,%lld,%lld,%d,%llu,%d\n",
                    arrived, expected, finish, wait, current,
                    done ? 1 : 0, (unsigned long long)rel, all ? 1 : 0);
    }

    // ---- B: grid bounds + rectangle size ----------------------------------
    for (int i = 0; i < 400; i++) {
        long long rows = pick(1, 16), cols = pick(1, 16);
        long long r = (pick(0,1) ? pick(0, rows - 1) : pick(0, 20));
        long long c = (pick(0,1) ? pick(0, cols - 1) : pick(0, 20));
        long long sr = pick(0, 10), sc = pick(0, 10);
        long long er = sr + pick(0, 5), ec = sc + pick(0, 5);

        Grid2D<int> g((size_t)rows, (size_t)cols, 0);
        int inb = g.inBounds((size_t)r, (size_t)c) ? 1 : 0;
        long long cell = -1;
        if (inb) cell = (long long)(&g((size_t)r, (size_t)c) - &g(0, 0));
        MulticastCoordSet mcs(Coord{0, (int16_t)sr, (int16_t)sc},
                              Coord{0, (int16_t)er, (int16_t)ec});
        long long rect = (long long)mcs.grid_size();
        std::printf("B,%lld,%lld,%lld,%lld,%lld,%lld,%lld,%lld,%d,%lld,%lld\n",
                    rows, cols, r, c, sr, sc, er, ec, inb, cell, rect);
    }
    return 0;
}
