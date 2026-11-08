module mac (clk, rst, valid, clear, A, B, acc);
  
  input clk, rst, valid, clear;
  input [7:0] A, B;
  output reg [31:0] acc;
  wire [15:0] O;
  wire [31:0] O_ext;
  wire [32:0] sum;
  
  //Multiply
  sig_mult_8bit mult (
    .A(A),
    .B(B),
    .O(O)
  );
  
  //Extend it to 32 bits
  assign O_ext = {{16{O[15]}},O};
  
  //Add to sum
  adder_32bit add (
    .a(acc),
    .b(O_ext),
    .ans(sum)
  );
  
  always @(posedge clk) begin
    if (rst || clear) acc <= 32'd0;
    else if (valid) acc <= sum[31:0];
  end
endmodule            
  