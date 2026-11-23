`timescale 1ns / 1ps

module pipe_stage
(
 input logic clk,
 input logic rst,
 input logic [7:0] in_data,
 input logic in_valid,
 output logic in_ready,
 input logic out_ready,
 output logic [7:0] out_data,
 output logic out_valid
);

//This register can accept data when
// 1) It is empty
// 2) Its value is being passed along

assign in_ready = !out_valid || out_ready;

always_ff @(posedge clk)begin
    //If system reset
    if(rst)begin
        out_valid <= 1'd0;
        out_data <= 8'd0;
    end
    //If ready to accept
    else if(in_valid && in_ready)begin
        out_data <= in_data;
        out_valid <= 1'd1;
    end
    //Nothing to accept, but curr data needs passing
    else if(out_ready && out_valid)begin
        out_valid <= 1'd0;
    end
    //If nothing stored, and nothing to receive: hold
    else begin
        out_data <= out_data;
    end
end
endmodule