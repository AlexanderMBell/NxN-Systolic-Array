# Physical Design Results (OpenROAD, Nangate45)

The sections below the Kogge-Stone section record the original ripple-carry design (RTL `4c9fb39`). The Kogge-Stone runs use RTL `5727a93` on the `kogge-stone` branch.

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

## PE clock sweep (ripple-carry design)

| Clock | Result | Worst slack | TNS | Power | Notes |
|---|---|---|---|---|---|
| 5.0 ns (200 MHz) | pass | +2.23 ns | 0 | 0.237 mW | relaxed, so the tools used small gates |
| 2.0 ns (500 MHz) | **fail** | -0.44 ns | -1.69 ns | not recorded | several `acc` bits fail |
| 2.5 ns (400 MHz) | pass | +0.02 ns | 0 | 0.454 mW | best passing run |

**PE result:** minimum period 2.48 ns, so **Fmax ≈ 403 MHz**. Cell area **1,064 µm²** (41% utilization).

### PE power breakdown at 2.5 ns (ripple-carry)

| Group | Total | Share |
|---|---|---|
| Sequential (flip-flops) | 0.182 mW | 40% |
| Combinational (logic) | 0.157 mW | 35% |
| Clock tree | 0.115 mW | 25% |
| **Total** | **0.454 mW** | internal 66%, switching 29%, leakage 5% |

Going from 200 MHz to 400 MHz roughly doubled the total power (0.237 → 0.454 mW), which is what dynamic power scaling with frequency predicts. Leakage stayed at about 21 µW.

### PE critical path at 2.5 ns, ripple-carry (`acc[0]` → `acc[31]`)

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


## Timing closure with the Kogge-Stone adder (PE)

**Goal:** close the PE at 500 MHz (2.0 ns), where the ripple-carry design failed by 0.44 ns (TNS −1.69 ns).

**Method:** replace one set of adders at a time with my parameterized Kogge-Stone adder, rerun every testbench, rerun the flow, and read the new critical path. Each run uses the same config as before (40% utilization, 20% I/O delay, typical corner).

| Step | Clock | Worst slack | Fmax | Cell area | Power | Critical path |
|---|---|---|---|---|---|---|
| Ripple-carry everywhere | 2.0 ns | −0.44 ns (fail) | 410 MHz (estimate) | n/a | n/a | `acc[0]` → `acc[31]` |
| Kogge-Stone accumulator | 2.0 ns | **+0.09 ns** | 525 MHz | 1,273 µm² | 0.600 mW at 500 MHz | `B_in[1]` → `prod_reg[15]` |
| Kogge-Stone everywhere | 1.67 ns | +0.58 ns | 704 MHz (estimate) | 1,525 µm² | 0.756 mW at 600 MHz | `A_in[0]` → `prod_reg[15]` |

### Clock sweep (Kogge-Stone everywhere)

| Clock | Worst slack | Estimated minimum period |
|---|---|---|
| 1.42 ns | +0.13 ns | 1.29 ns |
| 1.30 ns | +0.09 ns | 1.21 ns |
| 1.20 ns | +0.07 ns | 1.13 ns |
| **1.10 ns** | **+0.00 ns** | **1.10 ns (converged)** |

**Final PE result:** **912 MHz** at 1.10 ns, 1,676 µm², 1.63 mW at 909 MHz. The critical path is `B_in[0]` → multiplier tree → `prod_reg[15]`.

### PPA comparison

| Version | Fmax | Cell area | Energy per cycle |
|---|---|---|---|
| Ripple-carry (2.5 ns) | 403 MHz | 1,064 µm² | 1.14 pJ |
| Kogge-Stone everywhere (1.67 ns) | ~704 MHz | 1,525 µm² (+43%) | 1.26 pJ (+11%) |
| Kogge-Stone, clock pushed (1.10 ns) | **912 MHz (2.3×)** | 1,676 µm² (+58%) | 1.79 pJ (+57%) |

- **Changing the adder structure** bought 75% more speed for 43% more area and about 11% more energy per cycle.
- **Pushing the clock** bought another 30% of speed for 10% more area, but energy per cycle rose 42%. Switching power more than doubled as the tools used bigger gates and more buffers. Past about 700 MHz, each extra MHz costs much more energy.
- Each time the clock was tightened, the estimated minimum period dropped too. At a tighter target the tools build a faster circuit, which is why the sweep had to be run rather than predicted from one run.

**Caveats:** typical corner only, and the I/O delay is 20% of the clock period, so the input paths' budget shrinks along with the clock. The 4×4 array has not yet been rerun with the Kogge-Stone adders.

Run reports are in `pd/pe/runs/` (`pe_ks_*` folders), with a combined `SUMMARY.txt`.

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

## Screenshots (`pd/ScreenShots/`)

- `PE_2p5s_CriticalPathOpenRoad.png`: PE layout with a carry-chain path highlighted
- `ArrayLayout_3p0s_OpenRoad.png`: full-color 4×4 array layout
- `Array_3p0s_CriticalPathOpenRoad.png`: 4×4 array critical path, metal layers hidden

## Next experiments

1. Run the 4×4 array with the Kogge-Stone adders.
2. Speed up the multiplier, now the critical path: a Wallace or Dadda tree of carry-save adders, or a rebalanced pipeline.
3. Compare my Kogge-Stone against the adder synthesis builds from `+`, at the same clock.
4. Narrow the accumulator to `16 + $clog2(N)` bits and measure the change in Fmax and area.
