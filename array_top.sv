`timescale 1ns / 1ps

module array_top
#(parameter N = 4)(
 input logic                       clk,
 input logic                       rst,
 input logic                       in_valid,
 output logic                      in_ready,
 output logic                      out_valid,
 input logic                       out_ready,
 input logic [N-1:0][7:0]          a,
 input logic [N-1:0][7:0]          b,
 output logic [N-1:0][N-1:0][31:0] c
);

localparam beats = 3*N - 1;

logic skid_valid;
logic array_ready;
logic [2*N*8-1:0] skid_data;

//Links skid buffer to array
skid_buffer #(.WIDTH(2*N*8)) inst(
 .clk(clk),
 .rst(rst),
 .in_valid(in_valid),
 .out_ready(array_ready),
 .in_data({a,b}),
 .in_ready(in_ready),
 .out_valid(skid_valid),
 .out_data(skid_data)
);

//prepare skid buffer output for array
logic [N-1:0][7:0] a2, b2;
assign {a2,b2} = skid_data;

logic en;
logic clear;
//array can take when it doesnt have other value
assign array_ready = !out_valid;
//skid can give, array isnt holding other value
assign en = skid_valid && array_ready;
//Reader is ready to take and array can give, clear after
assign clear = out_ready && out_valid;

//call array and feed skid data
nxn_systolic_array #(.N(N)) arrayinst(
 .clk(clk),
 .rst(rst),
 .clear(clear),
 .en(en),
 .valid(1'b1),
 .a(a2),
 .b(b2),
 .c(c)
);

//count the amount of beats to track progress until finish
logic [$clog2(beats)-1:0] count;

always_ff @(posedge clk) begin
if(rst)begin
    count <= '0;
    out_valid <= 1'b0;
end
else if(out_valid && out_ready) begin
    out_valid <= 1'b0;
end
else if(en)begin
    if(count == beats-1)begin
        out_valid <= 1'b1;
        count <= '0;
    end
    else begin
        count <= count + 1'b1;
    end
end
end

endmodule