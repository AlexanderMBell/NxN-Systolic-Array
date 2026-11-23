`timescale 1ns/ 1ps

module skid_buffer_tb;

logic clk = 0;
logic rst;
logic [7:0] in_data, out_data;
logic in_valid, out_valid, in_ready, out_ready;

always #5 clk = ~clk;

skid_buffer inst
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
    
    //Cycle 1: sender offers 10, both slots empty
    in_data = 10;
    in_valid = 1;
    out_ready = 1;
    #1;
    $display("Cycle 1 before edge: in_ready = %0d (Exp: 1)",in_ready);
    @(negedge clk);
    $display("Cycle 1 after edge: out_valid = %0d, out_data = %0d (Exp: 1,10)",out_valid,out_data);
    
    //Cycle 2: sender offers 20, receiver suddenly busy
    //in_ready only looks at the skid slot (still empty), so 20 is accepted into skid
    in_data = 20;
    out_ready = 0;
    #1;
    $display("Cycle 2 before edge: in_ready = %0d (Exp: 1, skid empty)",in_ready);
    @(negedge clk);
    $display("Cycle 2 after edge: out_valid = %0d, out_data = %0d (Exp: 1,10; 20 is in skid)",out_valid,out_data);
    
    //Cycle 3: 20 was already accepted, so the sender moves on to 30
    //Skid is full, so in_ready = 0 and 30 must wait. Receiver takes 10, 20 moves skid -> main
    in_data = 30;
    out_ready = 1;
    #1;
    $display("Cycle 3 before edge: in_ready = %0d (Exp: 0, skid full)",in_ready);
    @(negedge clk);
    $display("Cycle 3 after edge: out_valid = %0d, out_data = %0d (Exp: 1,20)",out_valid,out_data);
    
    //Cycle 4: skid empty again, so 30 is accepted. Receiver takes 20
    #1;
    $display("Cycle 4 before edge: in_ready = %0d (Exp: 1, skid empty)",in_ready);
    @(negedge clk);
    $display("Cycle 4 after edge: out_valid = %0d, out_data = %0d (Exp: 1,30)",out_valid,out_data);
    
    //Cycle 5: sender is empty, receiver takes 30
    in_valid = 0;
    @(negedge clk);
    $display("Cycle 5 after edge: out_valid = %0d (Exp: 0)",out_valid);
    $finish;
end
endmodule