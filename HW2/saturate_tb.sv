module saturate_tb();
    logic   [9:0]   u_in_10;
    logic   [6:0]   u_out_7, u_expect_7;
    saturate #(.IN_WIDTH(10), .OUT_WIDTH(7), .IS_SIGNED(0)) i_sat_u_10_7(
        .in_val(u_in_10), .out_val(u_out_7)
    );

    logic   [4:0]   u_in_5;
    logic   [2:0]   u_out_3, u_expect_3;
    saturate #(.IN_WIDTH(5), .OUT_WIDTH(3), .IS_SIGNED(0)) i_sat_u_5_3(
        .in_val(u_in_5), .out_val(u_out_3)
    );

    logic   [13:0]  u_in_14;
    logic   [7:0]   u_out_8, u_expect_8;
    saturate #(.IN_WIDTH(14), .OUT_WIDTH(8), .IS_SIGNED(0)) i_sat_u_14_8(
        .in_val(u_in_14), .out_val(u_out_8)
    );

    logic   [11:0]  s_in_12;
    logic   [9:0]   s_out_10, s_expect_10;
    saturate #(.IN_WIDTH(12), .OUT_WIDTH(10), .IS_SIGNED(1)) i_sat_s_12_10(
        .in_val(s_in_12), .out_val(s_out_10)
    );

    logic   [10:0]  s_in_11;
    logic   [5:0]   s_out_6, s_expect_6;
    saturate #(.IN_WIDTH(11), .OUT_WIDTH(6), .IS_SIGNED(1)) i_sat_s_11_6(
        .in_val(s_in_11), .out_val(s_out_6)
    );

    initial begin
        // Test unsigned 10 to 7 doesn't saturate
        u_in_10 = 10'h02F;
        u_expect_7 = 7'h2F;
        #5;
        if (u_out_7 !== u_expect_7) begin
            $display("Test 1 failed: in=%d, out=%d, expected=%d\n",
                u_in_10, u_out_7, u_expect_7);
            $stop();
        end

        // Test unsigned 10 to 7 does saturate
        u_in_10 = 10'h37E;
        u_expect_7 = 7'h7F;
        #5;
        if (u_out_7 !== u_expect_7) begin
            $display("Test 2 failed: in=%d, out=%d, expected=%d\n",
                u_in_10, u_out_7, u_expect_7);
            $stop();
        end

        // Test unsigned 10 to 7 saturating edge
        u_in_10 = 10'h07F;
        u_expect_7 = 7'h7F;
        #5;
        if (u_out_7 !== u_expect_7) begin
            $display("Test 3 failed: in=%d, out=%d, expected=%d\n",
                u_in_10, u_out_7, u_expect_7);
            $stop();
        end

        // Test unsigned 5 to 3 non-sat
        u_in_5 = 5'h02;
        u_expect_3 = 3'h02;
        #5;
        if (u_out_3 !== u_expect_3) begin
            $display("Test 4 failed: in=%d, out=%d, expected=%d\n",
                u_in_5, u_out_3, u_expect_3);
            $stop();
        end

        // Test unsigned 5 to 3 sat
        u_in_5 = 5'h14;
        u_expect_3 = 3'h07;
        #5;
        if (u_out_3 !== u_expect_3) begin
            $display("Test 5 failed: in=%d, out=%d, expected=%d\n",
                u_in_5, u_out_3, u_expect_3);
            $stop();
        end

        // Test unsigned 14 to 8 non-sat
        u_in_14 = 14'h00C2;
        u_expect_8 = 8'hC2;
        #5;
        if (u_out_8 !== u_expect_8) begin
            $display("Test 6 failed: in=%d, out=%d, expected=%d\n",
                u_in_14, u_out_8, u_expect_8);
            $stop();
        end

        // Test unsigned 14 to 8 sat
        u_in_14 = 14'h4D3;
        u_expect_8 = 8'hFF;
        #5;
        if (u_out_8 !== u_expect_8) begin
            $display("Test 7 failed: in=%d, out=%d, expected=%d\n",
                u_in_14, u_out_8, u_expect_8);
            $stop();
        end

        // Test signed pos 12 to 10 sat
        s_in_12 = 12'h7F2;
        s_expect_10 = 10'h1FF;
        #5;
        if (s_out_10 !== s_expect_10) begin
            $display("Test 8 failed: in=%d, out=%d, expected=%d\n",
                $signed(s_in_12), $signed(s_out_10), $signed(s_expect_10));
            $stop();
        end

        // Test signed neg 12 to 10 sat
        s_in_12 = 12'h801;
        s_expect_10 = 10'h200;
        #5;
        if (s_out_10 !== s_expect_10) begin
            $display("Test 9 failed: in=%d, out=%d, expected=%d\n",
                $signed(s_in_12), $signed(s_out_10), $signed(s_expect_10));
            $stop();
        end

        // Test signed pos 12 to 10 non-sat
        s_in_12 = 12'h061;
        s_expect_10 = 10'h061;
        #5;
        if (s_out_10 !== s_expect_10) begin
            $display("Test 10 failed: in=%d, out=%d, expected=%d\n",
                $signed(s_in_12), $signed(s_out_10), $signed(s_expect_10));
            $stop();
        end

        // Test signed neg 12 to 10 non-sat
        s_in_12 = 12'hFE2;
        s_expect_10 = 10'hFE2;
        #5;
        if (s_out_10 !== s_expect_10) begin
            $display("Test 11 failed: in=%d, out=%d, expected=%d\n",
                $signed(s_in_12), $signed(s_out_10), $signed(s_expect_10));
            $stop();
        end

        // Test signed pos 11 to 6 sat
        s_in_11 = 11'h3FA;
        s_expect_6 = 6'h1F;
        #5;
        if (s_out_6 !== s_expect_6) begin
            $display("Test 12 failed: in=%d, out=%d, expected=%d\n",
                $signed(s_in_11), $signed(s_out_6), $signed(s_expect_6));
            $stop();
        end

        // Test signed neg 11 to 6 sat
        s_in_11 = 11'h403;
        s_expect_6 = 6'h20;
        #5;
        if (s_out_6 !== s_expect_6) begin
            $display("Test 13 failed: in=%d, out=%d, expected=%d\n",
                $signed(s_in_11), $signed(s_out_6), $signed(s_expect_6));
            $stop();
        end

        // Test signed pos 11 to 6 non-sat
        s_in_11 = 11'h015;
        s_expect_6 = 6'h15;
        #5;
        if (s_out_6 !== s_expect_6) begin
            $display("Test 14 failed: in=%d, out=%d, expected=%d\n",
                $signed(s_in_11), $signed(s_out_6), $signed(s_expect_6));
            $stop();
        end

        // Test signed neg 11 to 6 non-sat
        s_in_11 = 11'h7EF;
        s_expect_6 = 6'h2F;
        #5;
        if (s_out_6 !== s_expect_6) begin
            $display("Test 15 failed: in=%d, out=%d, expected=%d\n",
                $signed(s_in_11), $signed(s_out_6), $signed(s_expect_6));
            $stop();
        end

        $display("All tests passed!\n");
        $stop();
    end
endmodule
