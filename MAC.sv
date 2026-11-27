module mac 
(
 input logic         clk,
 input logic         rst,
 input logic         valid,
 input logic         clear,
 input logic [7:0]   A,
 input logic [7:0]   B,
 input logic         en,
 output logic [31:0] acc
);

  logic [15:0] O;
  logic [31:0] O_ext;
  logic [32:0] sum;
  logic [15:0] prod_reg;
  logic valid_delay;

  //Multiply
  sig_mult_8bit mult (
    .A(A),
    .B(B),
    .O(O)
  );
  
  //Extend it to 32 bits
  assign O_ext = {{16{prod_reg[15]}},prod_reg};
  
  //Add to sum
   kogge_stone #(.WIDTH(32)) add (
    .a(acc),
    .b(O_ext),
    .ans(sum)
  );
  
  always_ff @(posedge clk) begin
    if (rst) begin
        prod_reg <= 16'd0;
        valid_delay <= 1'b0;
        acc <= 32'd0;
    end
    else if (clear) begin
        acc <= 32'd0;
        valid_delay <= 1'b0;
    end
    else if (en) begin
        //this is a register between the multiply and sum functions
        prod_reg <= O;
        //this is a register to preserve the validity of the value above
        valid_delay <= valid;
        if(valid_delay) acc <= sum[31:0];
        //hold (defualt)
        else acc <= acc;
    end
  end
endmodule            
  