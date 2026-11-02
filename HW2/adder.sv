module adder(
    input logic [3:0] op1, op2,
    input logic cin,
    output logic [3:0] sum,
    output logic co
);
    logic [4:0] big_sum;
    
    assign big_sum = cin + op1 + op2;

    assign sum = big_sum[3:0];
    assign co = big_sum[4];
endmodule