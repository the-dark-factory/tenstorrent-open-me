# tenstorrent-open-me

Machine-checked proofs about **tt-npe**, Tenstorrent's network-on-chip performance
estimator, and one defect found while reading it.

> ### ⚠ Danger, Will Robinson — an LLM is loose in this repository.
>
> It read the C++, wrote the prose specifications, drove the factory that generated
> the Ada, and built the harnesses. Over one session it formed **five** hypotheses
> about defects in tt-npe: **one was real and is reproduced below; three were wrong
> and were refuted by reading further; one is unresolved and is asked as a question,
> not asserted.** It also made claims about its *own* work that its own tests then
> destroyed — see "What we got wrong", which is kept rather than tidied away.
>
> Nothing here was posted, sent, or published by the machine. A human read it first.

> ### ⛔ None of this has been tested on silicon.
> Every result concerns tt-npe **as software**, on commodity x86-64. Nothing here
> says whether tt-npe models the hardware correctly — that is a different question
> and we cannot answer it.
> The Blackhole FMA cores are the same: they agree with Tenstorrent's C **reference
> model**, and none of it has run on a card.

---

## Why this repository exists

Tenstorrent is an open-source company. So are we. We were reading tt-npe for our own
reasons — we build a factory that turns prose specifications into machine-proved
SPARK Ada, and we wanted a real target rather than a toy — and tt-npe fits, because
it is Apache-2.0, small enough to reason about, and **runs without silicon**.

We found something while we were in there. This is that, plus the working.

**There is no ask attached.** Not a bounty claim, not a request for hardware.

---

## The defect

On Blackhole, any workload containing `fabric_send` events fails ingest with
`TRACE_INGEST_FAILED`.

`DeviceArch` has exactly two members. Both `switch` statements on it in the
repository omit `break` on the Blackhole case, so it falls into a `default:` that
logs *"Unknown device model"* and throws — a branch otherwise unreachable.

Same trace file, same chip count, only the architecture differs:

```
T3K       = WormholeMultichipDeviceModel(8)   ->  INGESTED OK
P150_X8   = BlackholeMultichipDeviceModel(8)  ->  E: Unknown device model: P150_X8
                                                  E: TRACE_INGEST_FAILED
```

`-Wimplicit-fallthrough` is absent from their otherwise curated warning set, and
they already run `-Werror` — so adding that one flag turns both into build failures.

Full report, reproduction and falsifier: `receipts/ttnpe-blackhole-fallthrough-observed.json`.

---

## The cores

Five SPARK packages in `cores/`, each proved with GNATprove at level 2, each
independently re-proved on separate hardware in a fresh container before being
recorded.

| package | covers |
|---|---|
| `transfer_progress_pkg` | bytes moved per transfer per timestep |
| `rate_resolution_pkg` | table interpolation, blend, injection cap, derate |
| `grid_bounds_pkg` | coordinates, bounds, multicast rectangles |
| `checkpoint_pkg` | dependency arrivals and release timing |
| `timestep_pkg` | the loop's control arithmetic |

They state properties the original relies on and never writes down: that an arrival
cannot overrun its expected count, that the interpolation divisor cannot be zero,
that a bandwidth cannot be zero, that the loop terminates.

---

## Seven more: drivers and tooling, not just the estimator

The five above are all tt-npe (a performance *estimator* — software that never
touches real hardware). These seven are different: they reproduce arithmetic from
**tt-umd** (Tenstorrent's user-mode driver, Apache-2.0) and from **tt-smi** /
**tt-topology** (the CLI tools that read board telemetry and configure multi-chip
Ethernet routing, both Apache-2.0). This is address arithmetic and bit-decoding that
runs closer to real silicon than anything above.

| package | covers | source |
|---|---|---|
| `tlb_window` | TLB window address arithmetic, overflow-safe bounds check | tt-umd |
| `sysmem_bounds` | host-buffer page alignment and DMA range bounds check | tt-umd |
| `l2cpu_shuffle` | L2CPU harvesting-mask bit permutation, proved a genuine bijection (round-trip identity, not just a formula match) | tt-umd |
| `dram_bank_mirror` | DRAM bank-mirroring index arithmetic; proves the underflow the C's if/else guard is *supposed* to prevent actually cannot happen | tt-umd |
| `pcie_alignment` | page-alignment and hugepage-size checks | tt-umd |
| `board_type_decode` | board-ID → board-type decode (re-forged 2026-09-15, Yang-checked) | tt-smi **and** tt-topology |
| `eth_xy_decode` | logical Ethernet port → physical NOC coordinate, proved injective (no two ports alias the same tile) | tt-topology |

`board_type_decode` is worth a second look: **tt-smi and tt-topology each carry
their own independent copy of this same decode, and the two copies have already
drifted apart** — tt-topology's is missing three board types (the Grayskull cards)
and one alias that tt-smi's has. This core is the union of both, proved total: it cannot raise, unlike tt-smi's copy.
A Yang run backs that up (see the differential tests below). It was not true of the
first version we published, which is recorded under "What we got wrong".

**Not everything attempted here proved.** One tt-umd core (ARC message-queue
ring-buffer disjointness — proving a producer's writes and a consumer's reads can
never land on the same physical slot) and one tt-smi core (the GDDR
training/BIST harvest-tolerance check) both hit the same wall: the property needs a
nonlinear arithmetic fact or a loop-free proof structure that the current coder
pass would not reliably produce, however the prose was phrased. Kept as open work,
not quietly dropped.

---

## The Blackhole FMA: a whole floating-point unit, bit-exact

Tenstorrent publishes bit-exact C reference models of its FMA hardware (fused
`x * y + z`) in **tt-isa-documentation** (`Miscellaneous/FMA/fma.c`, Apache-2.0).
The Blackhole variant, `fma_model_bh`, departs from IEEE 754 on purpose, and says
so: denormal inputs are flushed to zero; a product that would overflow on its own
becomes infinity; a product that would underflow on its own is treated as exactly
zero; the sticky bit uses a truncated mask; denormal *results* are flushed after
rounding.

These cores re-express **the whole of `fma_model_bh`** in SPARK, not a sample of it.

| package | covers |
|---|---|
| `bh_fma_primitives` | exponent and mantissa fields (denormal flush), the semi-sticky shift |
| `bh_fma_msb` | highest set bit and leading-zero count, exact |
| `bh_fma_special` | the NaN / infinity block, proved never to return a finite value |
| `bh_fma_align_add` | exponent alignment and sign-magnitude addition, 64- and 32-bit widths exactly as the C has them |
| `bh_fma_normalize_round` | normalisation, round-to-nearest-even, denormal flush, proved sign-preserving and never denormal |
| **`bh_fma`** | **the complete `fma_model_bh`**, composed from the above (37 expression functions) |
| `fma_diff_verdict_pkg` | the acceptance rule for the FMA differential test below, so the verdict is a proof, not a script |

Proved about `Bh_Fma.Fma_Bh` for **every one of the 2⁹⁶ input triples**: no runtime
error; total (it has no precondition); and **it never returns a denormal**: the
result either has a non-zero exponent field or is exactly a signed zero.

A proof shows the Ada meets its contract. It cannot show the contract is the right
formula. So the FMA row of the differential tests below runs `Bh_Fma` against
Tenstorrent's own `fma.c`, unmodified.

⚠ **Scope:** that is agreement with Tenstorrent's **reference model**. No Blackhole
card was involved.

---

## The differential tests

`harnesses/` drives the upstream code and these cores over identical inputs and
diffs them.

| comparison | rows | result |
|---|---|---|
| checkpoint — against **their compiled code** | 400 | 0 mismatches |
| grid bounds — against **their compiled code** | 400 | 0 mismatches |
| `interpolateBW` — against **their compiled code** | 498 | every row within its own predicted quantisation |
| transfer progress — against a **transcription** ⚠ | 600 | 0 mismatches |
| timestep — against a **transcription** ⚠ | 600 | 210 divergences, all explained |
| `fma_model_bh` — against **their unmodified C** | 20,064,000 | 0 mismatches; NaN, infinity, zero and finite results all reached |
| `board_type_decode` — against **their code**, tt-smi and tt-topology at once | 38 | agrees with tt-smi on every well-formed ID; differs only on malformed input |

The last two are **weaker evidence** and are labelled as such everywhere: those
expressions are not callable, so they were copied. If the copy is wrong, those two
rows are worthless in a way the first three are not.

Every result was **mutation-checked first** — a differential reporting agreement is
worthless unless it can report disagreement.

The FMA row goes further: its verdict is issued by `fma_diff_verdict_pkg`, a proven
core, through a forged edge. The probe script only relays numbers (`harnesses/fma_diff_probe.bb`).
Its inputs: all 64,000 triples of 40 special values, plus 20,000,000 random triples,
half of them forced onto exponent edges. Its mutant run flips one bit of the Ada
result and must see all 65,000 cases disagree. A separate, informational run of
2,000,064,000 triples also found 0 mismatches. `fma.c` itself is not redistributed;
see NOTICE.

The `board_type_decode` row compares against both upstream copies at once. Each
original `get_board_type` was extracted verbatim from tt-smi `005fc6f` and
tt-topology `7bd675f` and run on the same 38 board IDs as this core; the full
three-way table is `receipts/board-type-decode-yang-table.txt`. The core agrees with
tt-smi on every well-formed ID (so it carries the Grayskull cards and the `0x202`
alias that tt-topology's copy lacks). The eight differences are all malformed input:
the core refuses it, where tt-smi raises `ValueError`, and where both originals
quietly accept a 17-digit ID and underscores (`1000_0431_0010_0123` decodes to
`p100a`) because Python's `int()` is lenient. The same run showed the two upstream
copies disagreeing on 10 of the 38 inputs.

---

## What we got wrong

Kept because a report that shows only its hits is not evidence of care.

- **"The byte-rate multiply loses float precision above 2²⁴."** Wrong. The
  multiplicand is the step-bounded active span, not the absolute cycle. 600 rows
  straddling that boundary: zero divergence. We reasoned from the *type* without
  checking which value reaches the line.
- **"Bandwidth starvation via an unclamped derate."** Refuted — the derate factor
  is positive.
- **"`interpolateBW` silently returns zero on failure."** Refuted — `TT_ASSERT` is
  not `NDEBUG`-gated and reaches a `[[noreturn]]` throw, so that `return 0` is dead
  code.
- **"`assert()` is compiled out in Release."** Refuted — their CMake sets
  `CMAKE_CXX_FLAGS_RELEASE` to just `-O3`, dropping CMake's default `-DNDEBUG`, so
  the bounds checks stay live.
- **The first FMA brief carried two bugs no proof could have caught.** It tested z's
  mantissa against `0x400000` *before* the C's `<<= 3` (the C compares the shifted
  value against `0x4000000`), which would have turned every `z = ∞` into NaN; and it
  gave the sticky shift a precondition, `Amount <= 128`, that the real call sites
  break (shifts reach 254). GNATprove would have proved the wrong formula faithfully.
  Both were found by reading the brief against the C before anything ran, which is
  the argument for the FMA differential test existing at all.
- **The first `board_type_decode` we published decoded every real board ID as `N/A`.**
  Its specification said in prose that the UPI is `(serial >> 36) & 0xFFFFF`, but the
  contract gave `Extract_Upi` only a bound (`<= 16#FFFFF#`). The separately written
  body masked the low 20 bits instead, which satisfies the bound, so the proof passed
  honestly and proved the wrong thing. A Yang run against Tenstorrent's own two copies
  caught it: 0 of 20 valid IDs decoded. The fault was in our specification, not the
  prover. The core was re-forged with every function written as its formula (nothing
  left for a separate body to get wrong), and the Yang re-run is in the table above.

tt-npe fails loudly and kept surviving attempts to break it. That is worth saying.

---

## The open question

`MulticastCoordSet`'s assertion says the first corner must be "to the top-left" of
the second, but tests `start.row <= end.row || start.col <= end.col` — a
disjunction where top-left is a conjunction. Ingest separately swaps the corners
for NOC_1, and the iterator visits exactly one coordinate when a rectangle is
inverted.

**We could not settle whether this fires**, because it depends on trace conventions
we do not have — every multicast event in both upstream fixtures is NOC_0 and
degenerate. So it is a question, not a finding.

---

## Licence

Apache-2.0 — the same licence as tt-npe. See `LICENSE` and `NOTICE`.
One harness contains upstream code verbatim and says so; `NOTICE` names it.
