`timescale 1ns / 1ps

module array_tb; 

//declare variables
parameter N = 8; 
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

initial begin
//Fill the matrices (for N = 2: A = [1 2; 3 4], B = [5 6; 7 8])
    for (int i = 0; i < N; i++)
      for (int j = 0; j < N; j++) begin
        A[i][j] = i*N + j + 1;
        B[i][j] = i*N + j + 5;
      end

//Correct answer: the textbook matrix multiply
    for (int i = 0; i < N; i++)
      for (int j = 0; j < N; j++) begin
        expected[i][j] = 0;
        for (int k = 0; k < N; k++)
          expected[i][j] += A[i][k] * B[k][j];
      end

//Reset
    rst = 1; 
    valid = 0; 
    clear = 0;
    a = 0; b = 0;
    @(negedge clk);
    rst = 0;
    valid = 1;

 //Feed the skewed inputs: 3N-2 cycles
    for (int t = 0; t < 3*N-2; t++) begin
      for (int i = 0; i < N; i++)
        a[i] = (t-i >= 0 && t-i < N) ? A[i][t-i] : 0;
      for (int j = 0; j < N; j++)
        b[j] = (t-j >= 0 && t-j < N) ? B[t-j][j] : 0;
      @(negedge clk);
    end

//Print every result next to the expected value
    for (int i = 0; i < N; i++)
      for (int j = 0; j < N; j++)
        $display("C[%0d][%0d] = %0d   (expect %0d)", i, j, $signed(c[i][j]), expected[i][j]);
    $finish;
end
endmodule