// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: © 2026 The Dark Factory Ltd
// Calls the upstream library through its own headers; copies no upstream code.
// DIFFERENTIAL ORACLE, part C — interpolateBW.
// The bandwidth VALUE is produced by tt-npe's own interpolateBW(). The only thing
// this file does itself is locate the table bracket (a lookup, not arithmetic) so
// the twin can be handed the same two table entries.
#include "npeDeviceModelUtils.hpp"
#include "device_models/blackhole.hpp"
#include <cstdio>
#include <cstdint>

using namespace tt_npe;

static uint64_t seed = 1234567890123ULL;
static uint64_t nxt() { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }
static long long pick(long long lo, long long hi) {
    return lo + (long long)(nxt() % (uint64_t)(hi - lo + 1));
}
static long long milli(double v) { return (long long)(v * 1000.0 + 0.5); }

int main() {
    BlackholeDeviceModel dm(BlackholeDeviceModel::DRAMHarvestingConfig::NO_HARVESTING);
    const TransferBandwidthTable &tbt = dm.getTransferBandwidthTable();
    float max_bw = dm.getMaxNoCTransferBandwidth();

    std::fprintf(stderr, "# their table (%zu entries), max_bw=%f\n", tbt.size(), max_bw);
    for (auto &e : tbt) std::fprintf(stderr, "#   size=%zu bw=%f\n", e.first, e.second);

    for (int i = 0; i < 500; i++) {
        // stay strictly inside the table so a bracket always exists
        long long lo_tab = (long long)tbt.front().first;
        long long hi_tab = (long long)tbt.back().first;
        long long ps = pick(lo_tab > 0 ? lo_tab : 1, hi_tab);
        long long np = pick(1, 64);

        // locate the bracket exactly as their loop does: first pair whose range covers ps
        long long ls = -1, hs = -1;
        double lr = 0, hr = 0;
        for (size_t k = 0; k + 1 < tbt.size(); k++) {
            if ((long long)tbt[k].first <= ps && ps <= (long long)tbt[k + 1].first) {
                ls = (long long)tbt[k].first;   lr = tbt[k].second;
                hs = (long long)tbt[k + 1].first; hr = tbt[k + 1].second;
                break;
            }
        }
        if (ls < 0) continue;            // outside the table: their fallback path, not this test
        if (ls == hs) continue;          // twin requires a strictly-increasing bracket

        float theirs = interpolateBW(tbt, max_bw, (size_t)ps, (size_t)np);

        // C,ps,np,low_size,high_size,low_rate_milli,high_rate_milli,max_bw_milli,their_bw_milli
        std::printf("C,%lld,%lld,%lld,%lld,%lld,%lld,%lld,%lld\n",
                    ps, np, ls, hs, milli(lr), milli(hr), milli(max_bw), milli(theirs));
    }
    return 0;
}
