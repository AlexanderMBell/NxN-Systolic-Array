module sig_mult_8bit
(
 input logic [7:0]   A,
 input logic [7:0]   B,
 output logic [15:0] O
);

  logic [15:0] A_ext;
  assign A_ext = {{8{A[7]}},A};
  
  logic [15:0] R0;
  assign R0 = (A_ext & {16{B[0]}}) << 0;
  
  logic [15:0] R1;
  assign R1 = (A_ext & {16{B[1]}}) << 1;
  
  logic [15:0] R2;
  assign R2 = (A_ext & {16{B[2]}}) << 2;
  
  logic [15:0] R3;
  assign R3 = (A_ext & {16{B[3]}}) << 3;
  
  logic [15:0] R4;
  assign R4 = (A_ext & {16{B[4]}}) << 4;
  
  logic [15:0] R5;
  assign R5 = (A_ext & {16{B[5]}}) << 5;
  
  logic [15:0] R6;
  assign R6 = (A_ext & {16{B[6]}}) << 6;
  
  logic [15:0] R7_pos;
  assign R7_pos = (A_ext & {16{B[7]}}) << 7;
  
  logic [15:0] R7;
  assign R7 = ~R7_pos + 16'd1;

  logic [16:0] sum01, sum23, sum45, sum67, sum0123, sum4567, sumF;
  
  //Group Independent adders to reduce timing
  
  //Branch 1
  kogge_stone #(.WIDTH(16)) add01 (.a(R0), .b(R1), .ans(sum01));
  kogge_stone #(.WIDTH(16)) add23 (.a(R2), .b(R3), .ans(sum23));
  kogge_stone #(.WIDTH(16)) add45 (.a(R4), .b(R5), .ans(sum45));
  kogge_stone #(.WIDTH(16)) add67 (.a(R6), .b(R7), .ans(sum67));
  
  //Branch 2
  kogge_stone #(.WIDTH(16)) add0123 (.a(sum01[15:0]), .b(sum23[15:0]), .ans(sum0123));
  kogge_stone #(.WIDTH(16)) add4567 (.a(sum45[15:0]), .b(sum67[15:0]), .ans(sum4567));
  
  //Branch 3
  kogge_stone #(.WIDTH(16)) addF (.a(sum0123[15:0]), .b(sum4567[15:0]), .ans(sumF));
  assign O = sumF[15:0];
    
endmodule

