# NxN Systolic Array | SystemVerilog

A parameterized NxN systolic array for signed 8-bit matrix multiplication, designed and implemented in SystemVerilog. The array multiplies two NxN matrices using a grid of N² processing elements (PEs), each built around a multiply-accumulate (MAC) unit. A single parameter, `N`, sets the array size.

The datapath's additions are built from my own full-adder and ripple-carry adder modules, and the signed 8-bit multiplier is a shift-and-add design rather than Verilog's built-in `*` operator. The one exception is the `+ 1` used to negate the multiplier's final partial product.

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
| `clear` | 1 | Synchronous clear: zeroes all accumulators before a new multiplication |
| `valid` | 1 | When high, every PE adds its current product to its accumulator |
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
- A shift-and-add array multiplier for two's-complement signed inputs.
- The multiplicand is sign-extended to 16 bits, and each bit of the multiplier selects a shifted copy of it as a partial product.
- Because the MSB of a two's-complement number has a weight of −2⁷, the final partial product is negated (two's complement) instead of added directly. I chose this sign-extension method over taking absolute values and fixing the sign afterward.
- The eight partial products are summed through a chain of seven 16-bit ripple-carry adders, producing a 16-bit signed product.

### 3. Multiply-Accumulate (MAC) Unit
- Multiplies the two 8-bit inputs, sign-extends the 16-bit product to 32 bits, and adds it to the running sum using the 32-bit adder.
- The accumulator register updates on the rising clock edge when `valid` is high, and is zeroed by `rst` or `clear`.

### 4. Processing Element (PE)
- Wraps a MAC unit with two output registers.
- Each cycle, a PE multiplies-and-accumulates the `A` value from its left neighbor and the `B` value from its top neighbor, then registers both values and passes them to its right and bottom neighbors on the next cycle.
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

The last multiply-accumulate happens at PE(N−1, N−1) on cycle 3(N − 1), so a full NxN matrix multiplication completes in **3N − 2 clock cycles**. Doing the same work with a single MAC unit would take N³ cycles, since the array performs up to N² multiplications in parallel.

| N | PEs | Array Cycles (3N − 2) | Single-MAC Cycles (N³) |
|---|-----|-----------------------|------------------------|
| 2 | 4 | 4 | 8 |
| 4 | 16 | 10 | 64 |
| 8 | 64 | 22 | 512 |
| 16 | 256 | 46 | 4,096 |

## Project Structure

| File | Module | Description |
|------|--------|-------------|
| `full_adder.sv` | `full_adder` | Gate-level 1-bit full adder |
| `adder_16bit.sv` | `adder_16bit` | 16-bit ripple-carry adder |
| `adder_32bit.sv` | `adder_32bit` | 32-bit ripple-carry adder |
| `sig_mult_8bit.sv` | `sig_mult_8bit` | Signed 8-bit shift-and-add multiplier |
| `MAC.sv` | `mac` | Multiply-accumulate unit with 32-bit accumulator |
| `PE.sv` | `pe` | Processing element: MAC plus pass-through registers |
| `NbyN_Systolic_Array.sv` | `nxn_systolic_array` | Parameterized top-level NxN array |
| `sig_mult_8bit_tb.sv` | `sig_mult_8bit_tb` | Exhaustive signed multiplier testbench |
| `MAC_tb.sv` | `mac_tb` | MAC testbench |
| `pe_tb.sv` | `pe_tb` | PE testbench |
| `array_tb.sv` | `array_tb` | Parameterized full-array testbench |

## Verification

### Signed Multiplier: Exhaustive Testing

The multiplier testbench applies all 65,536 signed 8-bit input pairs (−128 to 127 for each input) and compares every product against the expected result. All 65,536 products are correct, including the edge case −128 × −128 = 16,384.

### MAC and PE: Directed Testing

The MAC and PE testbenches apply a sequence of inputs and check the accumulated result after each clock cycle. They cover:
- Reset behavior
- Accumulating positive, negative, and mixed-sign products (2 × 3, −4 × 5, −3 × −6)
- Holding the accumulator when `valid` is low
- Clearing the accumulator with `clear`
- Forwarding `A` and `B` to the PE outputs one cycle later

### Full Array: Reference-Model Testing

The array testbench is parameterized by the same `N` as the design, so one value sets the size of the array, the edge inputs, the matrices, and the test. It:
1. Fills the input matrices `A` and `B`
2. Computes the expected result with a textbook triple-loop matrix multiply
3. Generates the skewed input schedule automatically: on cycle *t*, row *i* receives `A[i][t − i]` and column *j* receives `B[t − j][j]`, or zero when that index is out of range
4. Runs the 3N − 2 cycle computation and compares all N² outputs against the expected result

The array matches the reference result for all N² outputs at N = 2, N = 4, and N = 8.

### In Progress

- [ ] **Randomized matrices:** run many randomized signed matrix multiplications, clearing the accumulators between runs
- [ ] **Edge cases:** identity, zero, and maximum-magnitude (−128) matrices

## Running the Project

1. Open the source files in a simulator that supports SystemVerilog (the top-level module uses packed multidimensional arrays).
2. Include all design files: `full_adder.sv`, `adder_16bit.sv`, `adder_32bit.sv`, `sig_mult_8bit.sv`, `MAC.sv`, and `PE.sv`, plus `NbyN_Systolic_Array.sv` for the full array.
3. Include the testbench you want to run: `sig_mult_8bit_tb.sv`, `MAC_tb.sv`, `pe_tb.sv`, or `array_tb.sv`.
4. Select that testbench as the simulation top-level module. For `array_tb`, set `parameter N` at the top of the file to choose the array size.
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
- SystemVerilog packed multidimensional arrays
- Designing hierarchical RTL with many instantiated modules

Most importantly, this project showed me how the matrix multiplication at the core of machine learning hardware, like Google's TPU, is built from the same full adders as my first ALU.

## Next Steps

My immediate next step is finishing the full-array verification by adding randomized and edge-case matrix tests.

After that, possible extensions include:

- Adding a controller FSM to generate the input skew and signal when results are ready
- Replacing the shift-and-add multiplier with a faster Booth or Wallace-tree design
- Supporting matrices larger than the array through tiling
- Synthesizing the design and analyzing how area and timing scale with `N`

My longer-term goal is to continue building toward more complex digital systems and ASIC design.
