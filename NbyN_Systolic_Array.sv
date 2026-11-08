module nxn_systolic_array #(parameter N = 4)(clk, valid, rst, clear, a, b , c);

input clk, valid, rst, clear;
//create every input bit of each row and column
input [N-1:0][7:0] a,b;
//c represents every bit of every resulting value at each row & column
output [N-1:0][N-1:0][31:0] c;

//Declare every wire for the array:

//a represents row, N rows so [0,1...N-1], but edge wires on R/L so [0,1...N] column wires.
wire [7:0] a_wire[0:N-1][0:N];
//b represents column, N columns so [0,1...N-1], but edge wires on T/B so [0,1...N] row wires.
wire [7:0] b_wire[0:N][0:N-1];

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
