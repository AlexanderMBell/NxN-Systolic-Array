`timescale 1ns / 1ps

module array_top_tb;

parameter N = 4;
localparam BEATS = 3*N - 1;

logic clk;
logic rst;
logic in_valid;
logic in_ready;
logic out_valid;
logic out_ready;
logic [N-1:0][7:0] a;
logic [N-1:0][7:0] b;
logic [N-1:0][N-1:0][31:0] c;

int A[N][N];
int B[N][N];
int exp_q[$];      // expected results waiting to be checked, oldest first
int errors;
int tests;
int sent;          // matrices fully sent

array_top #(.N(N)) dut (
 .clk(clk),
 .rst(rst),
 .in_valid(in_valid),
 .in_ready(in_ready),
 .out_valid(out_valid),
 .out_ready(out_ready),
 .a(a),
 .b(b),
 .c(c)
);

always #5 clk = ~clk;

//---------------------------------------------------------------
// SENDER: one matrix = BEATS skewed beats, with random gaps.
// Rule 1: once a beat is offered, hold it until it's accepted.
//---------------------------------------------------------------
task automatic send_matrix(input bit base);
  int sum;

  // pick A and B
  for (int i = 0; i < N; i++) begin
    for (int j = 0; j < N; j++) begin
      if (base) begin
        A[i][j] = i*N + j + 1;
        B[i][j] = i*N + j + 5;
      end
      else begin
        A[i][j] = $urandom_range(0,255) - 128;
        B[i][j] = $urandom_range(0,255) - 128;
      end
    end
  end

  // expected C = A x B, pushed in i,j order (the reader pops in the same order)
  for (int i = 0; i < N; i++) begin
    for (int j = 0; j < N; j++) begin
      sum = 0;
      for (int k = 0; k < N; k++) sum += A[i][k] * B[k][j];
      exp_q.push_back(sum);
    end
  end

  // send the beats (driven on negedge, like the old testbench)
  for (int t = 0; t < BEATS; t++) begin
    // random idle gap: sender "isn't ready" for 0+ cycles
    while ($urandom_range(0,2) == 0) begin
      in_valid = 1'b0;
      @(negedge clk);
    end

    // build beat t: same skew + zero padding as array_tb_sc
    for (int i = 0; i < N; i++) begin
      if (t - i >= 0 && t - i < N) a[i] = A[i][t-i];
      else                         a[i] = 8'd0;
    end
    for (int j = 0; j < N; j++) begin
      if (t - j >= 0 && t - j < N) b[j] = B[t-j][j];
      else                         b[j] = 8'd0;
    end
    in_valid = 1'b1;

    // hold until accepted: in_ready is registered, so its value now
    // is what the next posedge will see
    while (!in_ready) @(negedge clk);
    @(negedge clk);   // the posedge in between took the beat
  end

  in_valid = 1'b0;
  sent++;
endtask

//---------------------------------------------------------------
// READER: random backpressure, check c whenever a result is taken
//---------------------------------------------------------------
always @(negedge clk) begin
  if (rst) out_ready = 1'b0;
  else     out_ready = ($urandom_range(0,1) != 0);   // ready ~2/3 of cycles
end

always @(posedge clk) begin
  if (!rst && out_valid && out_ready) begin
    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        int exp_val;
        exp_val = exp_q.pop_front();
        if ($signed(c[i][j]) != exp_val) begin
          $display("ERROR test %0d c[%0d][%0d]: got %0d, expected %0d",
                   tests, i, j, $signed(c[i][j]), exp_val);
          errors++;
        end
      end
    end
    tests++;
  end
end

//---------------------------------------------------------------
// MAIN
//---------------------------------------------------------------
initial begin
  clk = 0;
  rst = 1;
  in_valid = 0;
  a = '0;
  b = '0;
  errors = 0;
  tests = 0;
  sent = 0;

  repeat (3) @(negedge clk);
  rst = 0;

  send_matrix(1);                         // base pattern
  repeat (1000) send_matrix(0);           // random matrices, random stalls

  wait (tests == sent);                   // let the reader drain the last result
  repeat (5) @(negedge clk);

  $display("Tests run: %0d, Errors: %0d", tests, errors);
  $finish;
end

// watchdog: a lost beat would hang the sender forever
initial begin
  #10_000_000;
  $display("TIMEOUT: tests=%0d sent=%0d (a beat or result got lost)", tests, sent);
  $finish;
end

endmodule