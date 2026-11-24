`timescale 1ns / 1ps

module skid_buffer
#(
 parameter WIDTH = 8
)(
 input logic clk,
 input logic rst,
 input logic in_valid,
 input logic out_ready,
 input logic [WIDTH-1:0] in_data,
 output logic in_ready,
 output logic out_valid,
 output logic [WIDTH-1:0] out_data
);

logic skid_valid;
logic [WIDTH-1:0] skid_data;

//data can only be received if skid slot is empty
assign in_ready = !skid_valid;

always_ff @(posedge clk)begin
 if(rst)begin
    out_valid <= 1'd0;
    out_data <= '0;
    skid_valid <= 1'd0;
    skid_data <= '0;
 end
 //Register pulls data from skid or sender
 else if(out_ready || !out_valid)begin
    //if skid has value to be pulled
    if(skid_valid)begin
        out_data <= skid_data;
        out_valid <= 1'd1;
        skid_valid <= 1'd0;
    end
    //no skid value, but sender is ready
    else if(in_ready && in_valid)begin
        out_data <= in_data;
        out_valid <= 1'd1;
    end
    //no skid value, sender has no data
    else begin
        out_valid <= 1'd0;
    end
 end
 //receiver is busy and main register is full
 else begin
    if(in_valid && in_ready)begin
        skid_data <= in_data;
        skid_valid <= 1'd1;
    end
 end
end

endmodule