module sig_mult_8bit (A, B, O);
  
  input [7:0] A, B;
  output [15:0] O;
  
  wire[15:0] A_ext = {{8{A[7]}},A};
  
  wire[15:0] R0 = (A_ext & {16{B[0]}}) << 0;
  wire[15:0] R1 = (A_ext & {16{B[1]}}) << 1;
  wire[15:0] R2 = (A_ext & {16{B[2]}}) << 2;
  wire[15:0] R3 = (A_ext & {16{B[3]}}) << 3;
  wire[15:0] R4 = (A_ext & {16{B[4]}}) << 4;
  wire[15:0] R5 = (A_ext & {16{B[5]}}) << 5;
  wire[15:0] R6 = (A_ext & {16{B[6]}}) << 6;
  wire[15:0] R7_pos = (A_ext & {16{B[7]}}) << 7;
  wire[15:0] R7 = ~R7_pos + 16'd1;
  
  wire[16:0] sum1, sum2, sum3, sum4, sum5, sum6, sum7;
	
  adder_16bit add1 (.a(R0), .b(R1), .ans(sum1));
  adder_16bit add2 (.a(sum1[15:0]), .b(R2), .ans(sum2));
  adder_16bit add3 (.a(sum2[15:0]), .b(R3), .ans(sum3));
  adder_16bit add4 (.a(sum3[15:0]), .b(R4), .ans(sum4));
  adder_16bit add5 (.a(sum4[15:0]), .b(R5), .ans(sum5));
  adder_16bit add6 (.a(sum5[15:0]), .b(R6), .ans(sum6));
  adder_16bit add7 (.a(sum6[15:0]), .b(R7), .ans(sum7));
  assign O = sum7[15:0];
    
endmodule

