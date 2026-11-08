`timescale 1ns / 1ps

module pe (clk, rst, valid, clear, A_in, B_in, A_out, B_out, acc);

input clk, rst, valid, clear;
input [7:0] A_in, B_in;
output reg [7:0] A_out, B_out;
output [31:0] acc;

mac inst (
    .clk(clk),
    .rst(rst),
    .valid(valid),
    .clear(clear),
    .A(A_in),
    .B(B_in),
    .acc(acc)
);

always @(posedge clk) begin
    if(rst) begin
        A_out <= 0;
        B_out <= 0;
    end
    else begin
        A_out <= A_in;
        B_out <= B_in;
    end
end

endmodule