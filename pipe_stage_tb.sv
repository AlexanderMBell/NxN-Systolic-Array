`timescale 1ns/ 1ps

module pipe_stage_tb;

logic clk = 0;
logic rst;
logic [7:0] in_data, out_data;
logic in_valid, out_valid, in_ready, out_ready;

always #5 clk = ~clk;

pipe_stage inst
(
 .clk(clk),
 .rst(rst),
 .in_valid(in_valid),
 .out_valid(out_valid),
 .in_ready(in_ready),
 .out_ready(out_ready),
 .in_data(in_data),
 .out_data(out_data)
);

initial begin
    //Reset
    rst = 1;
    out_ready = 0;
    in_valid = 0;
    in_data = 0;
    @(negedge clk);
    rst = 0;
    
    //Cycle 1: sender offers 10, empty register
    in_data = 10;
    in_valid = 1;
    out_ready = 1;
    #1;
    $display("Cycle 1 before edge: in_ready = %0d (Exp: 1)",in_ready);
    @(negedge clk);
    $display("Cycle 1 after edge: out_valid = %0d, out_data = %0d (Exp: 1,10)",out_valid,out_data);
    
    //Cycle 2: sender offers 20, receiver deny
    in_data = 20;
    out_ready = 0;
    #1;
    $display("Cycle 2 before edge: in_ready = %0d (Exp: 0)",in_ready);
    @(negedge clk);
    $display("Cycle 2 after edge: out_valid = %0d, out_data = %0d (Exp: 1,10)",out_valid,out_data);
    
    //Cycle 3: receiver ready, sender still offer 20
    in_data = 20;
    out_ready = 1;
    #1;
    $display("Cycle 3 before edge: in_ready = %0d (Exp: 1)",in_ready);
    @(negedge clk);
    $display("Cycle 3 after edge: out_valid = %0d, out_data = %0d (Exp: 1,20)",out_valid,out_data);
    
    //Cycle 4: sender is empty, receiver takes 20
    in_valid = 0;
    @(negedge clk);
    $display("Cycle 4 after edge: out_valid = %0d (Exp: 0)",out_valid);
    $finish;
end
endmodule