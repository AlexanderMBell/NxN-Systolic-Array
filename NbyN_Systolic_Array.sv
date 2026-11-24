module nxn_systolic_array#(parameter N = 4)
(
 input logic                       clk,
 input logic                       valid,
 input logic                       rst,
 input logic                       clear,
 input logic                       en,
 input logic [N-1:0][7:0]          a,
 input logic [N-1:0][7:0]          b,
 output logic [N-1:0][N-1:0][31:0] c
);

//Wire Creation: A values come in from the left side, B values come in from the top side.
//Create all a value wires: For N=4, we need 4 rows ([0:N-1]) and 5 columns for edges ([0:N]).
logic [7:0] a_wire[0:N-1][0:N];
//Create all b value wires for N=4, we need 5 rows for edges ([0:N]) and 4 columns ([0:N-1]).
logic [7:0] b_wire[0:N][0:N-1];

genvar i,j;
generate 

//Connect initial values to initial wires:
for(i = 0; i<N; i = i+1) begin : edges
    assign a_wire[i][0] = a[i];
    assign b_wire[0][i] = b[i];
end

//Make NxN PEs and connect all wires:
for(i=0;i<N;i=i+1)begin : row
    for(j=0;j<N;j=j+1)begin : column
        pe inst (
            .clk(clk),
            .rst(rst),
            .valid(valid),
            .clear(clear),
            .en(en),
            .A_in(a_wire[i][j]),
            .B_in(b_wire[i][j]),
            //working across rows, each PE in row will incrememnt column value for a, and row value for b.
            .A_out(a_wire[i][j+1]),
            .B_out(b_wire[i+1][j]),
            //collect value at same pe.
            .acc(c[i][j])
        );
    end
end

endgenerate
endmodule
