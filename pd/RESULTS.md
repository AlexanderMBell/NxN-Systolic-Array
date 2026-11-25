# Physical Design Results (OpenROAD, Nangate45)

## Setup

| Item | Value |
|---|---|
| Flow | OpenROAD-flow-scripts (ORFS), run through `util/docker_shell` |
| ORFS commit | `9707faf5c` |
| Docker image | `openroad/orfs:latest` (pulled 2026-11-24) |
| Platform / corner | Nangate45, typical corner only |
| RTL version | `4c9fb39` |
| Core utilization | 40% |
| I/O delay | 20% of the clock period on every non-clock input and output |
| Synthesis | ORFS defaults (Yosys + ABC), design flattened |

## PE clock sweep

| Clock | Result | Worst slack | TNS | Power | Notes |
|---|---|---|---|---|---|
| 5.0 ns (200 MHz) | pass | +2.23 ns | 0 | 0.237 mW | relaxed, so the tools used small gates |
| 2.0 ns (500 MHz) | **fail** | -0.44 ns | -1.69 ns | not recorded | several `acc` bits fail |
| 2.5 ns (400 MHz) | pass | +0.02 ns | 0 | 0.454 mW | best passing run |

**PE result:** minimum period 2.48 ns, so **Fmax ≈ 403 MHz**. Cell area **1,064 µm²** (41% utilization).

### PE power breakdown at 2.5 ns

| Group | Total | Share |
|---|---|---|
| Sequential (flip-flops) | 0.182 mW | 40% |
| Combinational (logic) | 0.157 mW | 35% |
| Clock tree | 0.115 mW | 25% |
| **Total** | **0.454 mW** | internal 66%, switching 29%, leakage 5% |

Going from 200 MHz to 400 MHz roughly doubled the total power (0.237 → 0.454 mW), which is what dynamic power scaling with frequency predicts. Leakage stayed at about 21 µW.

### PE critical path at 2.5 ns (`acc[0]` → `acc[31]`)

| Step | Delay |
|---|---|
| Clock network delay (2 levels of `CLKBUF_X3`) | 0.08 ns |
| `acc[0]` clock-to-Q (`DFF_X1`) | 0.09 ns |
| Bit 0 half adder (`HA_X1`; carry-in is constant 0) | 0.03 ns |
| 30 full adders (`FA_X1`), carry-in to carry-out | about 0.07–0.08 ns each, **2.19 ns total** |
| Final sum logic for bit 31 (XNOR/NOR) | 0.12 ns |
| **Data arrival** | **2.52 ns** |
| Required (2.5 ns + 0.08 ns clock latency − 0.04 ns setup) | 2.54 ns |
| **Slack** | **+0.02 ns** |

**Conclusion:** the 32-bit ripple-carry accumulator in the MAC limits Fmax, at about 75 ps per bit. Clock skew is about 0 ns, and there are no slew, capacitance, fanout or hold violations.

## 4×4 array (`array_top`, N = 4)

| Item | Value |
|---|---|
| Clock | 3.0 ns (333 MHz): **pass**, worst slack about +0.20 ns |
| Fmax | **≈ 357 MHz** (minimum period ≈ 2.80 ns) |
| Cell area | **17,360 µm²**, about 2% more than 16 × the PE |
| Chip size | about 210 × 210 µm (from the screenshot scale bar) |
| Power | **4.90 mW** at 333 MHz (internal 3.44, switching 1.15, leakage 0.31 mW) |
| Clock network delay | 0.201 ns (vs 0.082 ns for the single PE) |
| Critical path | the carry chain inside PE `row[2].column[2]` (`HA_X1` then a chain of `FA_X1`) |

**Why the array is slower than one PE:** the critical logic is the same carry chain. The array's clock tree and wires are longer, so there is less time left for the logic.

### Array power breakdown at 3.0 ns

| Group | Total | Share |
|---|---|---|
| Sequential (flip-flops) | 2.63 mW | 54% |
| Clock tree | 1.77 mW | 36% |
| Combinational (logic) | 0.51 mW | 10% |
| **Total** | **4.90 mW** | internal 70%, switching 24%, leakage 6% |

Clocking the flip-flops and driving the clock tree account for about **90% of the array's power**. This makes clock gating (with the existing `en` signal) the obvious power-saving target. The numbers come from the tool's default switching-activity estimate, not from real data patterns.

In the array the critical path's carry steps take about 80 ps per full adder (vs about 73 ps in the standalone PE), and the hold-critical path is in the control logic (`out_valid` → `skid_valid`).

**Power check:** leakage is 0.31 mW, about 16 × the PE's 21 µW, as expected for 16 copies. The dynamic power is lower than 16 × the PE's, because this run is at a slower clock (333 vs 400 MHz) and the relaxed timing let the tools use smaller gates.

**Why the area is only about 2% over 16 PEs:** the unused `A_out` and `B_out` flip-flops on the array's edges are removed, and the 3.0 ns clock let the tools use smaller gates than the 2.5 ns PE run. The skid buffer, beat counter and enable buffer trees add only a little on top.

## Screenshots (`pd/images/`)

- `PE_2p5s_CriticalPathOpenRoad.png`: PE layout with a carry-chain path highlighted
- `ArrayLayout_3p0s_OpenRoad.png`: full-color 4×4 array layout
- `Array_3p0s_CriticalPathOpenRoad.png`: 4×4 array critical path, metal layers hidden

## Next experiments

1. Replace the hand-built 32-bit ripple adder with `acc + O_ext` and let synthesis choose the adder. Rerun the 2.0 ns PE.
2. Narrow the accumulator to `16 + $clog2(N)` bits. Measure the change in Fmax and area.
3. Set a real target (500 MHz for the PE) and close timing against it.
