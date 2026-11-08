`timescale 1ns / 1ps

//16-bit Addition Module
module adder_32bit (a, b, ans);

  // I/Os
  input[31:0] a;
  input[31:0] b;
  output[32:0] ans;

  wire[32:0] carry;

  assign carry[0] = 0;

  //Extend from 1b to 16b
  genvar i;
  generate
    for (i=0; i < 32; i = i + 1)
    begin

      full_adder inst (
        .input_1(a[i]),
        .input_2(b[i]),
        .c_in(carry[i]),
        .s_2(ans[i]),
        .c_2(carry[i+1])
      );
    end
  endgenerate

  //17th bit indicates final bit carry.
  assign ans[32] = carry[32];

endmodule

