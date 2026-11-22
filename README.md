# NxN Systolic Array | SystemVerilog

A parameterized NxN systolic array for signed 8-bit matrix multiplication, designed and implemented in SystemVerilog. The array multiplies two NxN matrices using a grid of N² processing elements (PEs), each built around a pipelined multiply-accumulate (MAC) unit. A single parameter, `N`, sets the array size.

The datapath's additions are built from my own full-adder and ripple-carry adder modules, and the signed 8-bit multiplier is a shift-and-add design rather than Verilog's built-in `*` operator. The one exception is the `+ 1` used to negate the multiplier's final partial product.

The RTL uses ANSI-style ports with `logic` and `always_ff`, and is lint-clean in Vivado (every remaining lint message is a documented, intentional waiver).

This project builds on my previous [8-bit ALU](https://github.com/AlexanderMBell/8-bit-ALU-Verilog) and is my first sequential, clocked digital design.

## What It Does

The array computes:

```
C = A × B
```

where `A` and `B` are NxN matrices of signed 8-bit integers.

| Port | Width | Description |
|------|-------|-------------|
| `clk` | 1 | Clock |
| `rst` | 1 | Synchronous reset: clears all accumulators and pipeline registers |
| `clear` | 1 | Synchronous clear: zeroes all accumulators before a new multiplication and discards any product still in the pipeline |
| `valid` | 1 | When high, the products computed this cycle are added to the accumulators (one cycle later, through the pipeline) |
| `a` | N × 8-bit | One value per row, fed into the left edge of the array each cycle |
| `b` | N × 8-bit | One value per column, fed into the top edge of the array each cycle |
| `c` | N × N × 32-bit | Result matrix, read directly from the PE accumulators |

| Parameter | Default | Description |
|-----------|---------|-------------|
| `N` | 4 | Array dimension (number of PE rows and columns) |

Each output element is the sum of N signed 8-bit × 8-bit products. Every product fits in 16 bits, and the 32-bit accumulators cannot overflow for any array up to N = 131,071.

## Architecture

The design is modular and built bottom-up, with each level instantiating the one below it.

### 1. Full Adder and Ripple-Carry Adders
- A gate-level full adder built from XOR, AND, and OR operations.
- 16-bit and 32-bit ripple-carry adders built by chaining full adders with a `generate` loop.

### 2. Signed 8-Bit Multiplier
- A shift-and-add multiplier for two's-complement signed inputs.
- The multiplicand is sign-extended to 16 bits, and each bit of the multiplier selects a shifted copy of it as a partial product.
- Because the MSB of a two's-complement number has a weight of −2⁷, the final partial product is negated (two's complement) instead of added directly. I chose this sign-extension method over taking absolute values and fixing the sign afterward.
- The eight partial products are summed with seven 16-bit ripple-carry adders arranged as a **3-level adder tree** (8 → 4 → 2 → 1), rather than a 7-deep chain, which shortens the critical path.

### 3. Multiply-Accumulate (MAC) Unit
- A **two-stage pipeline**:
  - **Stage 1:** multiply the two 8-bit inputs and register the 16-bit product (`prod_reg`).
  - **Stage 2:** sign-extend the registered product to 32 bits and add it to the accumulator using the 32-bit adder.
- `valid` is delayed one cycle (`valid_d`) so it stays aligned with the product it describes.
- `clear` zeroes the accumulator immediately and marks the product being multiplied that cycle as invalid, so it can't leak into the next sum.

### 4. Processing Element (PE)
- Wraps a MAC unit with two output registers.
- Each cycle, a PE multiplies the `A` value from its left neighbor and the `B` value from its top neighbor, then registers both values and passes them to its right and bottom neighbors on the next cycle.
- Because each partial sum stays inside its PE, the array uses an **output-stationary** dataflow.

### 5. Top-Level NxN Array
- Nested `generate` loops instantiate N² PEs and wire them into a grid, with `A` values flowing left-to-right and `B` values flowing top-to-bottom.
- Each PE's accumulator connects directly to its element of the output matrix `c`.

```
              b[0]         b[1]               b[N-1]
                ↓            ↓                   ↓
a[0]    →   [PE 0,0]   → [PE 0,1]   → ... → [PE 0,N-1]
                ↓            ↓                   ↓
a[1]    →   [PE 1,0]   → [PE 1,1]   → ... → [PE 1,N-1]
                ↓            ↓                   ↓
               ...          ...                 ...
                ↓            ↓                   ↓
a[N-1]  →  [PE N-1,0]  → [PE N-1,1]  → ... → [PE N-1,N-1]
```

## Input Scheduling and Timing

The array expects its inputs to be skewed in time: row *i* of `A` is fed in *i* cycles late, and column *j* of `B` is fed in *j* cycles late, with zeros on any edge input that has no data yet. Combined with the one-cycle register delay in each PE, this makes `A[i][k]` and `B[k][j]` arrive at PE(*i*, *j*) on the same cycle, *i + j + k*.

The last pair meets at PE(N−1, N−1) on cycle 3(N − 1). Counting from cycle 0, that is 3N − 2 cycles to multiply every pair. The MAC pipeline adds one more cycle before the last product reaches its accumulator, so a full NxN matrix multiplication completes in **3N − 1 clock cycles**. Doing the same work with a single MAC unit would take N³ cycles, since the array performs up to N² multiplications in parallel.

| N | PEs | Array Cycles (3N − 1) | Single-MAC Cycles (N³) |
|---|-----|-----------------------|------------------------|
| 2 | 4 | 5 | 8 |
| 4 | 16 | 11 | 64 |
| 8 | 64 | 23 | 512 |
| 16 | 256 | 47 | 4,096 |

## Timing Results

Synthesized out-of-context in Vivado for an Artix-7 (`xc7a12ticsg325-1L`) at N = 4, with a 10 ns (100 MHz) clock constraint. Figures are post-synthesis estimates.

| Version | WNS | Critical Path | Fmax |
|---------|-----|---------------|------|
| Original (7-adder ripple chain) | −4.587 ns | 14.59 ns | 68.6 MHz |
| Adder tree (3 levels) | −1.921 ns | 11.92 ns | 83.9 MHz |
| Pipelined MAC | +2.286 ns | 7.71 ns | **129.6 MHz** |

Static timing analysis showed the original critical path ran from a neighboring PE's `A_out` register, through the full multiplier, and up the 32-bit accumulator adder. Restructuring the multiplier as an adder tree shortened that path by 18%, and pipelining the MAC split it across two cycles, for a 1.9× total improvement in Fmax at the cost of one extra cycle of latency.

## Project Structure

| File | Module | Description |
|------|--------|-------------|
| `full_adder.sv` | `full_adder` | Gate-level 1-bit full adder |
| `adder_16bit.sv` | `adder_16bit` | 16-bit ripple-carry adder |
| `adder_32bit.sv` | `adder_32bit` | 32-bit ripple-carry adder |
| `sig_mult_8bit.sv` | `sig_mult_8bit` | Signed 8-bit shift-and-add multiplier with a 3-level adder tree |
| `MAC.sv` | `mac` | Two-stage pipelined multiply-accumulate unit with 32-bit accumulator |
| `PE.sv` | `pe` | Processing element: MAC plus pass-through registers |
| `NbyN_Systolic_Array.sv` | `nxn_systolic_array` | Parameterized top-level NxN array |
| `sig_mult_8bit_tb.sv` | `sig_mult_8bit_tb` | Exhaustive signed multiplier testbench |
| `MAC_tb.sv` | `mac_tb` | MAC testbench |
| `pe_tb.sv` | `pe_tb` | PE testbench |
| `array_tb_sc.sv` | `array_tb_sc` | Self-checking full-array testbench |

## Verification

### Signed Multiplier: Exhaustive Testing

The multiplier testbench applies all 65,536 signed 8-bit input pairs (−128 to 127 for each input) and compares every product against the expected result. All 65,536 products are correct, including the edge case −128 × −128 = 16,384.

### MAC and PE: Directed Testing

The MAC and PE testbenches apply a sequence of inputs and check the accumulated result after each clock cycle, accounting for the one-cycle pipeline latency. They cover:
- Reset behavior
- Accumulating positive, negative, and mixed-sign products (2 × 3, −4 × 5, −3 × −6)
- Holding the accumulator when `valid` is low
- Clearing the accumulator with `clear`, including clearing while valid data is on the inputs (the in-flight product must not leak into the new sum)
- Forwarding `A` and `B` to the PE outputs one cycle later

### Full Array: Self-Checking Regression

The array testbench is parameterized by the same `N` as the design, so one value sets the size of the array, the edge inputs, the matrices, and the test. A reusable task runs one complete multiplication:
1. Computes the expected result with a textbook triple-loop matrix multiply (the reference model)
2. Pulses `clear` so each test starts from zero, which also tests `clear` between back-to-back runs
3. Generates the skewed input schedule automatically: on cycle *t*, row *i* receives `A[i][t − i]` and column *j* receives `B[t − j][j]`, or zero when that index is out of range
4. Compares all N² outputs against the expected result and counts mismatches

The regression runs a fixed base pattern followed by 1,000 random signed matrices (values from −128 to 127). Result: **1,001 tests, 0 errors** at N = 8.

### In Progress

- [ ] **Multiple sizes:** run the randomized regression at N = 2 and N = 4
- [ ] **Edge cases:** identity, zero, and maximum-magnitude (−128) matrices

## Running the Project

1. Open the source files in a simulator that supports SystemVerilog (the top-level module uses packed multidimensional arrays).
2. Include all design files: `full_adder.sv`, `adder_16bit.sv`, `adder_32bit.sv`, `sig_mult_8bit.sv`, `MAC.sv`, and `PE.sv`, plus `NbyN_Systolic_Array.sv` for the full array.
3. Include the testbench you want to run: `sig_mult_8bit_tb.sv`, `MAC_tb.sv`, `pe_tb.sv`, or `array_tb_sc.sv`.
4. Select that testbench as the simulation top-level module. For `array_tb_sc`, set `parameter N` at the top of the file to choose the array size.
5. Run the simulation and inspect the printed results.

## What I Learned

Through this project, I gained practical experience with:

- Sequential logic, clocking, and registers
- Synchronous reset, clear, and enable (`valid`) control signals
- Building a signed multiplier from adders and partial products
- Two's-complement signed arithmetic and sign extension
- Choosing datapath widths to prevent overflow
- Multiply-accumulate units and how they underpin matrix math
- Systolic array dataflow and input skewing
- Parameterized RTL and nested `generate` loops
- Modern SystemVerilog style (ANSI ports, `logic`, `always_ff`) and linting
- Self-checking testbenches with randomized tests and a reference model
- Static timing analysis: clock constraints, WNS/TNS, and critical paths
- Improving Fmax with logic restructuring (adder trees) and pipelining, and keeping control signals aligned with pipelined data

Most importantly, this project showed me how the matrix multiplication at the core of machine learning hardware, like Google's TPU, is built from the same full adders as my first ALU.

## Next Steps

- Replacing the global `valid` with valid/ready handshakes, skid buffers, and FIFOs so the array can stall correctly
- Double buffering, so the next matrices load while the current ones compute
- Wrapping the array with AXI4-Stream and AXI4-Lite interfaces
- Comparing the hand-built multiplier with a DSP-based version across array sizes
- Taking the array through an RTL-to-GDS flow

My longer-term goal is to continue building toward more complex digital systems and ASIC design.
