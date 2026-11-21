`timescale 1ns / 1ps

module full_adder
(
 input logic  input_1,
 input logic  input_2,
 input logic  c_in,
 output logic s_2,
 output logic c_2
);

  logic c_i;
  logic s_i;

  //Intermediate Sum/Carry
  assign s_i = input_1 ^ input_2;
  assign c_i = input_1 & input_2;

  //Determine Carry-over and Sum
  assign s_2 = s_i ^ c_in;
  assign c_2 = c_i | (s_i & c_in);

endmodule