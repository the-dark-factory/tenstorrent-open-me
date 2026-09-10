// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: © 2025 Tenstorrent AI ULC   (the copied statements)
// SPDX-FileCopyrightText: © 2026 The Dark Factory Ltd (the surrounding harness)
//
// CHANGED FROM THE ORIGINAL: the statements below are lifted out of the body of
// runSinglePerfSim() and driven directly. Each is reproduced verbatim in a
// comment above it with its upstream line number, so the copy can be audited.
// ============================================================================
//  ⚠ TRANSCRIPTION ORACLE — WEAKER EVIDENCE THAN PARTS A/B/C. READ THIS FIRST.
//
//  Parts A, B and C called tt-npe's own compiled code. This file CANNOT: the
//  expressions below live inside the body of runSinglePerfSim() and are not
//  reachable as functions. So they are COPIED here.
//
//  That means this compares our twin against OUR TRANSCRIPTION of their code,
//  not against their code. If the transcription is wrong, the comparison is
//  worthless in a way the earlier parts are not.
//
//  Mitigation: every transcribed line is reproduced verbatim in the comment
//  above it, with its file and line number, so the copy can be audited against
//  the original. Types are theirs: Cycle = uint64_t, total_bytes = uint32_t,
//  total_bytes_transferred = size_t, curr_bandwidth = float.
// ============================================================================
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>

using Cycle = uint64_t;   // npeCommon.hpp:14

static uint64_t seed = 999777555333ULL;
static uint64_t nxt() { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }
static long long pick(long long lo, long long hi) {
    return lo + (long long)(nxt() % (uint64_t)(hi - lo + 1));
}

int main() {
    // ---- D: transfer progress -------------------------------------------
    // npeEngine.cpp:281  size_t remaining_bytes = lt.params.total_bytes - lt.total_bytes_transferred;
    // npeEngine.cpp:282  Cycle cycles_active_in_curr_timestep =
    // npeEngine.cpp:283      std::min(cfg.cycles_per_timestep, curr_cycle - lt.start_cycle);
    // npeEngine.cpp:293  size_t max_transferrable_bytes = cycles_active_in_curr_timestep * lt.curr_bandwidth;
    // npeEngine.cpp:297  size_t bytes_transferred = std::min(remaining_bytes, max_transferrable_bytes);
    // npeEngine.cpp:298  lt.total_bytes_transferred += bytes_transferred;
    for (int i = 0; i < 600; i++) {
        // integer-valued bandwidth so the twin's whole-byte rate is comparable
        long long rate      = pick(1, 4096);
        long long step      = pick(1, 1024);
        // span the float-precision boundary deliberately: 2^24 = 16777216
        long long start_cyc = (pick(0, 2) == 0) ? pick(0, 5000)
                            : (pick(0, 1) == 0) ? pick(16000000, 17000000)
                                                : pick(30000000, 50000000);
        long long cur_cyc   = start_cyc + pick(0, 2048);
        long long total     = pick(1, 4000000);
        long long moved     = pick(0, total);

        uint32_t total_bytes            = (uint32_t)total;
        size_t   total_bytes_transferred = (size_t)moved;
        float    curr_bandwidth          = (float)rate;
        Cycle    cycles_per_timestep     = (Cycle)step;
        Cycle    curr_cycle              = (Cycle)cur_cyc;
        Cycle    lt_start_cycle          = (Cycle)start_cyc;

        size_t remaining_bytes = total_bytes - total_bytes_transferred;
        Cycle cycles_active_in_curr_timestep =
            std::min(cycles_per_timestep, curr_cycle - lt_start_cycle);
        size_t max_transferrable_bytes = cycles_active_in_curr_timestep * curr_bandwidth;
        size_t bytes_transferred = std::min(remaining_bytes, max_transferrable_bytes);
        size_t after = total_bytes_transferred + bytes_transferred;

        std::printf("D,%lld,%lld,%lld,%lld,%lld,%lld,%llu,%llu,%llu\n",
                    total, moved, rate, step, start_cyc, cur_cyc,
                    (unsigned long long)cycles_active_in_curr_timestep,
                    (unsigned long long)bytes_transferred,
                    (unsigned long long)after);
    }

    // ---- E: timestep control --------------------------------------------
    // npeEngine.cpp:226  Cycle start_of_timestep = (curr_cycle - cfg.cycles_per_timestep);
    // npeEngine.cpp:227  Cycle prev_start_of_timestep = start_of_timestep - cfg.cycles_per_timestep;
    // npeEngine.cpp:229  return cycle >= prev_start_of_timestep && cycle < start_of_timestep;
    // npeEngine.cpp:350  curr_cycle += cfg.cycles_per_timestep;
    for (int i = 0; i < 600; i++) {
        long long step = pick(1, 1024);
        // include the FIRST pass, where curr_cycle == step exactly
        long long cur  = (pick(0, 2) == 0) ? step : pick(step, 40000);
        long long test = pick(0, 40000);

        Cycle cycles_per_timestep = (Cycle)step;
        Cycle curr_cycle          = (Cycle)cur;

        Cycle start_of_timestep      = (curr_cycle - cycles_per_timestep);
        Cycle prev_start_of_timestep = start_of_timestep - cycles_per_timestep;
        bool in_prev = ((Cycle)test >= prev_start_of_timestep && (Cycle)test < start_of_timestep);
        Cycle advanced = curr_cycle + cycles_per_timestep;

        std::printf("E,%lld,%lld,%lld,%llu,%llu,%d,%llu\n",
                    step, cur, test,
                    (unsigned long long)start_of_timestep,
                    (unsigned long long)prev_start_of_timestep,
                    in_prev ? 1 : 0,
                    (unsigned long long)advanced);
    }
    return 0;
}
