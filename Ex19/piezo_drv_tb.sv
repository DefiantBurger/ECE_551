module piezo_drv_tb ();
    logic clk, rst_n, en_steer, too_fast, batt_low, piezo, piezo_n;

    // 64 recommended by pdf but still too slow
    localparam int SIM_INCR = 512;

    // clocks in one 3s repeat period at this speedup
    localparam int RPT_CLKS = 150_000_000 / SIM_INCR;

    initial clk = 0;
    always #5 clk <= !clk;

    piezo_drv #(
        .FAST_SIM(1),
        .SIM_INCR(SIM_INCR)
    ) iDUT (
        .clk(clk),
        .rst_n(rst_n),
        .en_steer(en_steer),
        .too_fast(too_fast),
        .batt_low(batt_low),
        .piezo(piezo),
        .piezo_n(piezo_n)
    );

    initial begin
        en_steer = 0;
        too_fast = 0;
        batt_low = 0;
        rst_n = 0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1;

        // no inputs: piezo should be silent
        repeat (RPT_CLKS / 5) @(posedge clk);

        // normal operation: charge fanfare every 3s
        en_steer = 1;
        repeat (RPT_CLKS * 2) @(posedge clk);

        // too_fast: first 3 notes continuously (priority)
        too_fast = 1;
        repeat (RPT_CLKS * 3 / 5) @(posedge clk);
        too_fast = 0;

        // batt_low (with en_steer still high): fanfare backwards every 3s
        batt_low = 1;
        repeat (RPT_CLKS * 2) @(posedge clk);

        // all off: should go silent
        en_steer = 0;
        batt_low = 0;
        repeat (RPT_CLKS) @(posedge clk);

        $stop();
    end

endmodule
