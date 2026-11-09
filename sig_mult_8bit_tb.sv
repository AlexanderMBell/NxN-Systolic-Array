module sig_mult_8bit_tb;

  reg signed [7:0] A,B;
  wire signed [15:0] O;
  int errors = 0;
  
  sig_mult_8bit inst (.A(A), .B(B), .O(O));
  
  initial begin
    for (int i = -128; i < 128; i = i + 1) begin
      for (int j = -128; j < 128; j = j + 1) begin
        A = i;
        B = j;
        #1; 
        if ( O !== i*j) begin
          $display("TB Fail: %0d * %0d = %0d", i, j, i*j);
          errors = errors + 1;
        end
      end
    end
    if (errors == 0) $display("TB PASS");
    else $display("TB: %0d failures", errors);
  end
endmodule