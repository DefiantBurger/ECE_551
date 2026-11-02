module saturate_tb();
    logic   [15:0]  unsigned_err, signed_err;
    logic   [9:0]   unsigned_err_sat, signed_err_sat, signed_D_diff;
    logic   [6:0]   signed_D_diff_sat;

    logic   [9:0]   expected_10b;
    logic   [6:0]   expected_7b;

    saturate iSATURATE(
        .unsigned_err(unsigned_err), 
        .unsigned_err_sat(unsigned_err_sat),
        .signed_err(signed_err),
        .signed_err_sat(signed_err_sat),
        .signed_D_diff(signed_D_diff),
        .signed_D_diff_sat(signed_D_diff_sat)
    );

    initial begin
        // 1: Test unsigned saturates
        unsigned_err = 16'hFFFF;
        expected_10b = 10'hFFF;
        #5;
        if (unsigned_err_sat !== expected_10b) begin
            $display("Test 1 failed: in=%d, out=%d, expected=%d\n",
                unsigned_err, unsigned_err_sat, expected_10b);
            $stop();
        end

        // 2: Test unsigned doesn't saturate
        unsigned_err = 16'h005A;
        expected_10b = 10'h05A;
        #5;
        if (unsigned_err_sat !== expected_10b) begin
            $display("Test 2 failed: in=%d, out=%d, expected=%d\n",
                unsigned_err, unsigned_err_sat, expected_10b);
            $stop();
        end

        // 3: Test unsigned saturating edge
        unsigned_err = 16'h03FF;
        expected_10b = 10'hFFF; // = 10'h3FF
        #5;
        if (unsigned_err_sat !== expected_10b) begin
            $display("Test 3 failed: in=%d, out=%d, expected=%d\n",
                unsigned_err, unsigned_err_sat, expected_10b);
            $stop();
        end

        // 4: Test unsigned non-saturating edge
        unsigned_err = 16'h01FF;
        expected_10b = 10'h1FF;
        #5;
        if (unsigned_err_sat !== expected_10b) begin
            $display("Test 4 failed: in=%d, out=%d, expected=%d\n",
                unsigned_err, unsigned_err_sat, expected_10b);
            $stop();
        end

        // 5: Test signed positive saturates
        signed_err = 16'h7FFF;
        expected_10b = 10'h1FF;
        #5;
        if (signed_err_sat !== expected_10b) begin
            $display("Test 5 failed: in=%d, out=%d, expected=%d\n",
                $signed(signed_err), $signed(signed_err_sat), $signed(expected_10b));
            $stop();
        end

        // 6: Test signed negative saturates
        signed_err = 16'h8000;
        expected_10b = 10'hE00; // same as 10'h200
        #5;
        if (signed_err_sat !== expected_10b) begin
            $display("Test 6 failed: in=%d, out=%d, expected=%d\n",
                $signed(signed_err), $signed(signed_err_sat), $signed(expected_10b));
            $stop();
        end

        // 7: Test signed positive doesn't saturate
        signed_err = 16'h0061;
        expected_10b = 10'h061;
        #5;
        if (signed_err_sat !== expected_10b) begin
            $display("Test 7 failed: in=%d, out=%d, expected=%d\n",
                $signed(signed_err), $signed(signed_err_sat), $signed(expected_10b));
            $stop();
        end

        // 8: Test signed negative doesn't saturate
        signed_err = 16'hFFE2;
        expected_10b = 10'hFE2;
        #5;
        if (signed_err_sat !== expected_10b) begin
            $display("Test 8 failed: in=%d, out=%d, expected=%d\n",
                $signed(signed_err), $signed(signed_err_sat), $signed(expected_10b));
            $stop();
        end

        // additional tests could test signed D, & edges of both signed args

        $display("All tests passed!\n");
        $stop();
    end
endmodule