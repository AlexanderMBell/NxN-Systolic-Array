`timescale 1ns / 1ps

module kogge_stone_tb;

parameter WIDTH = 16;

//variables
logic [WIDTH-1:0] a,b;
logic [WIDTH:0] ans;
logic [WIDTH:0] exp;
int errors;
int tests;

//instantiate
kogge_stone #(.WIDTH(WIDTH)) inst
(
 .a(a),
 .b(b),
 .ans(ans)
);

//task for checking
task check();
 #1;
 //concatinate a 0 into a to ensure WIDTH+1 bit sum
 exp = {1'b0,a} + b;
 tests++;
 //check if wrong
 if(ans !== exp)begin
    errors = errors + 1;
    $display("ERROR: %0d + %0d = %0d, expected %0d", a, b, ans, exp);
 end
endtask

//initial block
initial begin
errors = 0;
tests = 0;

//check worst edge case:
a = '1;
b = 1;
check();

//100k random tests:
repeat(100000)begin
a = $urandom;
b = $urandom;
check();
end

$display("WIDTH=%0d  Tests run: %0d, Errors: %0d", WIDTH, tests, errors);
$finish();

end
endmodule