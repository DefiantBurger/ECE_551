module arith_tb();

logic error;
logic [7:0] true_val;
logic [7:0] A, B;
logic SUB;
wire [7:0] SUM;
wire OV;

arith iArith(.A(A), .B(B), .SUB(SUB), .SUM(SUM), .OV(OV));

initial begin
    error = 1'b0;

    // Testing 0x5A + 0x12 = 0x6C
    A = 8'h5A;
    B = 8'h12;
    SUB = 1'b0;
    true_val = 8'h6C;
    #10;

    if (SUM !== true_val || OV !== 1'b0) begin
        error |= 1'b1;
    end

    // Testing 0x5A - 0x12 = 0x49
    SUB = 1'b1;
    true_val = 8'h48;
    #10;

    if (SUM !== true_val || OV !== 1'b0) begin
        error |= 1'b1;
    end

    // Testing 0x00 + 0x2F = 0x2F
    A = 8'h00;
    B = 8'h2F;
    SUB = 1'b0;
    true_val = 8'h2F;
    #10;

    if (SUM !== true_val || OV !== 1'b0) begin
        error |= 1'b1;
    end

    // Testing 0xFF + 0x01 = 0x00 without overflow
    A = 8'hFF;
    B = 8'h01;
    SUB = 1'b0;
    true_val = 8'h00;
    #10;

    if (SUM !== true_val || OV !== 1'b0) begin
        error |= 1'b1;
    end

    // Testing 0x7F + 0x01 = 0x80 with overflow
    A = 8'h7F;
    B = 8'h01;
    SUB = 1'b0;
    true_val = 8'h80;
    #10;

    if (SUM !== true_val || OV !== 1'b1) begin
        error |= 1'b1;
    end

    // Testing 0x80 + 0x80 = 0x00 with overflow
    A = 8'h80;
    B = 8'h80;
    SUB = 1'b0;
    true_val = 8'h00;
    #10;

    if (SUM !== true_val || OV !== 1'b1) begin
        error |= 1'b1;
    end

    // Testing 0x80 - 0x01 = 0x7F with overflow
    A = 8'h80;
    B = 8'h01;
    SUB = 1'b1;
    true_val = 8'h7F;
    #10;

    if (SUM !== true_val || OV !== 1'b1) begin
        error |= 1'b1;
    end
    // ^ this test case caught the bug because it passed a positive B,
    // but then subtracted it causing overflow without the original
    // arith.sv detecting the overflow.

    if (!error)
        $display("All tests passed!");
    else
        $display("Some or all tests failed!");

    #10;

    $stop;
end

endmodule