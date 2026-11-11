// Self-checking TB: A2D_intf talking to the ADC128S model over SPI.
// Does 8 conversions and checks each lands in the right holding register.
module A2D_tb ();
    logic rst_n;

    logic clk;
    always #5 clk <= ~clk;  // 10ns period, speed doesn't matter in sim
    initial clk = 0;

    logic a2d_SS_n, SCLK, MOSI, MISO;

    logic nxt;
    logic [11:0] lft_ld, rght_ld, steer_pot, batt;

    A2D_intf i_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .nxt(nxt),
        .MISO(MISO),
        .lft_ld(lft_ld),
        .rght_ld(rght_ld),
        .steer_pot(steer_pot),
        .batt(batt),
        .SS_n(a2d_SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI)
    );

    // provided model of the on-board A2D
    ADC128S i_ADC128S (
        .clk  (clk),
        .rst_n(rst_n),
        .SS_n (a2d_SS_n),
        .SCLK (SCLK),
        .MISO (MISO),
        .MOSI (MOSI)
    );

    // lft(0), rght(4), steer(5), batt(6)
    localparam logic [2:0] CHNLS[4] = '{3'd0, 3'd4, 3'd5, 3'd6};

    // Pulse nxt, wait for both SPI transactions, then check the holding
    // register for conversion k. ADC model returns (0xC00 - 0x10*k) | channel.
    task automatic check(input int k);
        logic [11:0] expected, actual;
        // starts at 0xC00, drops 0x010 per read, channel # in the low nibble
        // (ex: 1st read ch 0 -> 0xC00, 2nd read ch 4 -> 0xBF4)
        expected = (12'hC00 - 12'h010 * k) | CHNLS[k%4]; // math :)

        // 1 clk pulse, like the 19-bit counter's full in A2D_test
        @(negedge clk) nxt = 1;
        @(negedge clk) nxt = 0;

        // wait for SS_n to go back high twice, bail if it hangs
        fork : watchdog
            begin
                repeat (2) @(posedge a2d_SS_n);
            end
            begin
                repeat (2000) @(posedge clk);
                $display("ERROR: conversion %0d timed out waiting for 2 SPI transactions", k);
                $stop;
            end
        join_any
        disable watchdog;

        // update fires the clock after done, register latches the clock after that
        repeat (3) @(negedge clk);

        // grab whichever register this conversion should have loaded
        case (k % 4)
            0: actual = lft_ld;
            1: actual = rght_ld;
            2: actual = steer_pot;
            3: actual = batt;
            default begin
                // nothing
            end
        endcase

        if (actual !== expected) begin
            $display("ERROR: conversion %0d (channel %0d): expected %h, got %h", k, CHNLS[k%4],
                     expected, actual);
            $stop;
        end else $display("conversion %0d (channel %0d): %h OK", k, CHNLS[k%4], actual);
    endtask

    initial begin
        // hold reset for a couple clocks
        nxt   = 0;
        rst_n = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
        repeat (2) @(negedge clk);

        // Two full trips around the round robin, so we also check
        // the counter wraps and the registers get overwritten
        for (int k = 0; k < 8; k++) check(k);

        $display("YAHOO! All tests passed");
        $stop;
    end

endmodule
