`timescale 1ns / 1ps

module pe_tb;

logic clk = 0;
logic rst, clear, valid;
logic signed [7:0] A_in,B_in;
logic signed [7:0] A_out,B_out;
logic signed [31:0] acc;

always #5 clk = ~clk;

pe inst(
    .clk(clk),
    .rst(rst),
    .valid(valid),
    .clear(clear),
    .A_in(A_in),
    .B_in(B_in),
    .A_out(A_out),
    .B_out(B_out),
    .acc(acc)
);

initial begin
//Test Reset:
valid = 0;
clear = 0;
rst = 1;
A_in = 0;
B_in = 0;
@(negedge clk);
$display("Reset Function: A_out = %d0, B_out = %d0 and acc = %d0", A_out, B_out, acc);

//Cycle 1:
rst = 0;
valid =1;
A_in = 2;
B_in = 3;
@(negedge clk);
$display("After 2,2 V=1: A_out = %d0, B_out = %d0 and acc = %d0", A_out, B_out, acc);

//Cycle 2:
A_in = -4;
B_in = 5;
@(negedge clk);
$display("After -4,5 V=1: A_out = %d0, B_out = %d0 and acc = %d0", A_out, B_out, acc);

//Cycle 3:
valid = 0;
A_in = 9;
B_in = 7;
@(negedge clk);
$display("After 9,7 V=0: A_out = %d0, B_out = %d0 and acc = %d0", A_out, B_out, acc);

//Cycle 4: (pipeline) one more cycle with valid off, so the 9*7 from cycle 3 must not be added
@(negedge clk);
$display("After extra cycle V=0: A_out = %d0, B_out = %d0 and acc = %d0", A_out, B_out, acc);

//Reset end
rst = 1;
@(negedge clk);
$display("After Reset: A_out = %d0, B_out = %d0 and acc = %d0", A_out, B_out, acc);


$finish;
end
endmodule