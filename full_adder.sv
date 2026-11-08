`timescale 1ns / 1ps

//Full-Adder Module (standalone)
module full_adder (input_1, input_2, c_in, s_2, c_2);

  // I/O
  input input_1;
  input input_2;
  input c_in;
  output s_2;
  output c_2;

  //Variables
  wire c_i;
  wire s_i;

  //Intermediate Sum/Carry
  assign s_i = input_1 ^ input_2;
  assign c_i = input_1 & input_2;

  //Determine Carry-over and Sum
  assign s_2 = s_i ^ c_in;
  assign c_2 = c_i | (s_i & c_in);

endmodule