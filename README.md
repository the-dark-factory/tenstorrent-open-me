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

The last two are **weaker evidence** and are labelled as such everywhere: those
expressions are not callable, so they were copied. If the copy is wrong, those two
rows are worthless in a way the first three are not.

Every result was **mutation-checked first** — a differential reporting agreement is
worthless unless it can report disagreement.

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
