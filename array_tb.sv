`timescale 1ns / 1ps 

module array_tb; 

//declare variables
parameter N = 2; 
reg clk = 0;
reg valid, clear, rst;
reg [N-1:0][7:0] a,b;          
wire [N-1:0][N-1:0][31:0] c;   
int A[N][N], B[N][N];                  
int expected[N][N];                    

//define our clock cycle
always #5 clk = ~clk;

//instantiate
nxn_systolic_array #(.N(N)) inst (
    .clk(clk),
    .valid(valid),
    .clear(clear),
    .rst(rst),
    .a(a),
    .b(b),
    .c(c)
);

//This test verifies that the array works under 1 base matrix, this does not exhaustivly verify it.
initial begin
//This always produces a base matrix, for example: N=2 generates A = [1 2; 3 4], B = [5 6; 7 8])
    for (int i = 0; i < N; i++)
      for (int j = 0; j < N; j++) begin
        //the constants are for making this specific base matrix.
        A[i][j] = i*N + j + 1;
        B[i][j] = i*N + j + 5;
      end

//Determines correct result through "inefficient" matrix multiplication.
    for (int i = 0; i < N; i++)
      for (int j = 0; j < N; j++) begin
        //initializes each index of the matrix.
        expected[i][j] = 0;
        //In A[i][k], K walks us along row I.
        //In B[k][j], K walks us down column J.
        //For each I,J,K we multiply and accumulate A[i][k] & B[k][j].
        for (int k = 0; k < N; k++)
          expected[i][j] += A[i][k] * B[k][j];
      end

//Reset everything, setting all values to 0.
    rst = 1; 
    valid = 0; 
    clear = 0;
    a = 0; b = 0;
    @(negedge clk);
    rst = 0;
    valid = 1;
    
    
//# of cycles fdr systolic goes as follows: 
// N=1 1 Cycle
// N=2 4 Cycles
// N=3 7 Cycles
// 1 + 3(N-1) Cycles or 3N-2 Cycles.

 //Setting values at the negedge, while the instantiated array module runs calcs at the posedge.
 //Feed the skewed inputs: 3N-2 cycles
    for (int t = 0; t < 3*N-2; t++) begin 
      for (int i = 0; i < N; i++)
      //a is 0 when it hasnt reached its turn or has done all its work
      //else a is set value when it has reached its turn and hasnt done its work
        a[i] = (t-i >= 0 && t-i < N) ? A[i][t-i] : 0;
      for (int j = 0; j < N; j++)
      //same concept as a.
        b[j] = (t-j >= 0 && t-j < N) ? B[t-j][j] : 0;
      //feed new values at negedge because posedge is used for calculations.
      @(negedge clk);
    end

//Print every result next to the expected value
    for (int i = 0; i < N; i++)
      for (int j = 0; j < N; j++)
        $display("C[%0d][%0d] = %0d   (expect %0d)", i, j, $signed(c[i][j]), expected[i][j]);
    $finish;
end
endmodule