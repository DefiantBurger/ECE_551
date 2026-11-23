module steer_en_tb ();

    logic clk, rst_n;
    logic [11:0] lft_ld, rght_ld;
    wire en_steer, rider_off;

    // FAST_SIM: timer fills after 2^15 = 32768 clocks instead of 2^26
    localparam int TMR_CLKS = 32768;

    int errors = 0;

    steer_en #(.FAST_SIM(1)) iDUT (
        .clk(clk),
        .rst_n(rst_n),
        .lft_ld(lft_ld),
        .rght_ld(rght_ld),
        .en_steer(en_steer),
        .rider_off(rider_off)
    );

    always #10 clk = ~clk;

    // Check outputs on the negedge so combinational outputs have settled
    task automatic check(input logic exp_en, input logic exp_off, input string msg);
        @(negedge clk);
        if (en_steer !== exp_en || rider_off !== exp_off) begin
            $display("FAIL: %s -- en_steer=%b (exp %b), rider_off=%b (exp %b) @ %0t",
                     msg, en_steer, exp_en, rider_off, exp_off, $time);
            errors++;
        end else $display("pass: %s", msg);
    endtask

    task automatic set_ld(input logic [11:0] l, input logic [11:0] r);
        @(negedge clk);
        lft_ld  = l;
        rght_ld = r;
    endtask

    initial begin
        clk     = 0;
        rst_n   = 0;
        lft_ld  = '0;
        rght_ld = '0;

        repeat (3) @(negedge clk);
        rst_n = 1;

        $display("=== steer_en testbench ===");

        // 1. Reset / nobody on board
        check(0, 1, "after reset: rider_off, no steer");

        // 2. Light load: sum = 0x200, inside hysteresis band (not > 0x240)
        set_ld(12'h100, 12'h100);
        repeat (10) @(negedge clk);
        check(0, 1, "sum in hysteresis band from INIT: still rider_off");

        // 3. Rider steps on balanced: sum = 0x300 > 0x240
        set_ld(12'h180, 12'h180);
        check(0, 0, "rider on, balancing: rider_off drops, no steer yet");

        repeat (TMR_CLKS - 2000) @(negedge clk);
        check(0, 0, "just short of timer: still no steer");

        repeat (3000) @(negedge clk);
        check(1, 0, "after timer: steering enabled");

        // 4. Hysteresis in BALANCED: sum = 0x200 (> 0x1C0) keeps riding
        set_ld(12'h100, 12'h100);
        repeat (10) @(negedge clk);
        check(1, 0, "sum in hysteresis band while riding: still steering");

        // 5. Moderate lean while riding: diff > 1/4 sum but < 15/16 sum
        //    sum = 0x300, diff = 0x100 (1/4 = 0xC0, 15/16 = 0x2D0)
        set_ld(12'h200, 12'h100);
        repeat (10) @(negedge clk);
        check(1, 0, "moderate lean while riding: still steering");

        // 6. Stepping off: diff > 15/16 sum
        //    sum = 0x310 (784), 15/16 = 735, diff = 0x2F0 (752)
        set_ld(12'h300, 12'h010);
        check(0, 0, "one foot off: steer disabled, rider still on");

        // 7. Wobble during balancing must restart the timer
        set_ld(12'h180, 12'h180);
        repeat (TMR_CLKS / 2) @(negedge clk);
        check(0, 0, "halfway through timer");

        set_ld(12'h200, 12'h100);  // diff > 1/4 sum: clears timer
        repeat (10) @(negedge clk);
        check(0, 0, "wobble: no steer");

        set_ld(12'h180, 12'h180);
        repeat (TMR_CLKS - 2000) @(negedge clk);
        // Without the clear, the timer would have filled by now
        check(0, 0, "timer restarted after wobble: still no steer");

        repeat (3000) @(negedge clk);
        check(1, 0, "full time after wobble: steering enabled");

        // 8. Rider knocked off from BALANCED: sum < 0x1C0
        set_ld(12'h000, 12'h000);
        check(0, 1, "knocked off while riding: back to rider_off");

        // 9. Step off during BALANCING goes straight to INIT
        set_ld(12'h180, 12'h180);
        repeat (100) @(negedge clk);
        set_ld(12'h080, 12'h080);  // sum = 0x100 < 0x1C0
        check(0, 1, "stepped off while balancing: rider_off");

        // 10. Timer must have been cleared in INIT too
        set_ld(12'h180, 12'h180);
        repeat (TMR_CLKS - 2000) @(negedge clk);
        check(0, 0, "re-mount: timer started fresh");

        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else $display("=== %0d TEST(S) FAILED ===", errors);
        $stop;
    end

endmodule

`default_nettype wire
