`timescale 1ns / 1ps

module pe
(
 input logic         clk,
 input logic         rst,
 input logic         valid,
 input logic         clear,
 input logic [7:0]   A_in,
 input logic [7:0]   B_in,
 output logic [7:0]  A_out,
 output logic [7:0]  B_out,
 output logic [31:0] acc
);

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