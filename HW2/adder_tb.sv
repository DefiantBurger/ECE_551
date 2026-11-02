module adder_tb();
    logic [3:0] op1, op2, sum;
    logic cin, co;

    adder i_DUT(
        .op1(op1), .op2(op2), .cin(cin), .sum(sum), .co(co)
    );

    logic [3:0] expected_sum;
    logic expected_co;

    initial begin
        for (int i = 0; i < 2; i++) begin
            cin = i;
            for (int k = 0; k < 16; k++) begin
                op1 = k;
                for (int m = 0; m < 16; m++) begin
                    op2 = m;
                    
                    expected_sum = 4'(cin + k + m);
                    expected_co = 1'((cin + k + m) >> 4);
                    #1
                    if (sum !== expected_sum || co !== expected_co) begin
                        $display("Test failed: %d + %d + %d = %d (c %b), got %d (c %b)\n",
                            cin, op1, op2, expected_sum, expected_co, sum, co);
                        $stop();
                    end
                end
            end
        end

        $display("All tests passed!\n");
        $stop();
    end
endmodule