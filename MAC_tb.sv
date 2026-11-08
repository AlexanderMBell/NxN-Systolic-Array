`timescale 1ns / 1ps

module mac_tb;

  reg clk = 0;
  reg rst, valid, clear;
  reg signed [7:0] A,B;
  wire signed [31:0] acc;

  always #5 clk = ~clk;

  mac tst (
    .clk(clk),
    .rst(rst),
    .valid(valid),
    .clear(clear),
    .A(A),
    .B(B),
    .acc(acc)
  );

  initial begin

    //Test Reset:
    rst = 1;
    clear = 0;
    valid = 0;
    A = 0;
    B = 0;
    @(negedge clk);
    rst = 0;

    //Test 1: 2 * 3
    valid = 1;
    A = 2;
    B = 3;
    @(negedge clk);
    $display("2*3 = (6) %0d",acc);

    //Test 2: -4 * 5
    A = -4;
    B = 5;
    @(negedge clk);
    $display("-4*5 = (-14) %0d",acc);

    //Test 3: -3 * -6
    A = -3;
    B = -6;
    @(negedge clk);
    $display ("-3*-6= (4) %0d",acc);

    //Test 4: valid off
    valid = 0;
    A = 9;
    B = 9;
    @(negedge clk);
    $display ("acc = (4) %0d",acc);

    //Test clear:
    clear = 1;
    @(negedge clk);
    $display ("acc = (0) %0d",acc);

    $finish;
  end 
endmodule
