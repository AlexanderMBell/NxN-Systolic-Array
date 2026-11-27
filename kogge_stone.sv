`timescale 1ns/1ps
module kogge_stone
#(parameter WIDTH=32)
(
 input logic [WIDTH-1:0] a,
 input logic [WIDTH-1:0] b,
 output logic [WIDTH:0] ans
);

 //number of tree levels
 localparam LEVELS = $clog2(WIDTH);

//g[k] = whole row for level k
//g[k][i] what bit i of level k
wire [WIDTH-1:0] g [0:LEVELS];
wire [WIDTH-1:0] p [0:LEVELS];

//Level 0:
//comes out to WIDTH AND gates, and WIDTH XOR gates.
assign g[0] = a&b; 
assign p[0] = a^b;

//Levels:
genvar k,i;
generate
    //level by level incrementer
    for (k=1;k<=LEVELS;k++)begin : level
        localparam dis = 1 << (k-1);
            for (i=0;i<WIDTH;i++)begin : cells
                //if i higher than d, this group reaches a lower bit not 0
                if (i >= dis)begin : combine
                    //find the generate for the new group, Gi = Gi or (Pi and Gi-d) 
                    assign g[k][i] = g[k-1][i] | (p[k-1][i] & g[k-1][i-dis]);
                    //find the propoagate for the new group, pi and pi-d
                    assign p[k][i] = p[k-1][i] & p[k-1][i-dis];
                end
                //if i is lower than d, this group will reach to 0
                else begin : pass
                    //if g or p for highest bit, then g or p for that bit to zero
                    assign g[k][i] = g[k-1][i];
                    assign p[k][i] = p[k-1][i];
                end
            end 
    end
endgenerate 

//Sum calculation
//answer at lowest bit is just a xor b for that bit (p[0][0])
assign ans[0] = p[0][0];

generate
    for(i=1;i<WIDTH;i++)begin : summing
        //SUM is calculated by XOR a and b fo that column, then XOR by the carry out of previous bit range to zero so g[LEVELS][i-1].
        assign ans[i] = p[0][i] ^ g[LEVELS][i-1];
    end
endgenerate

//final answer bit is just carry out of last bit
assign ans[WIDTH] = g[LEVELS][WIDTH-1];

endmodule