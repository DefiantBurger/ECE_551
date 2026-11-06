module UART_tb;
    localparam int HALF_CLK = 10;  // 50 MHz clock -> 20 ns period
    localparam int BAUD = 5208;  // clocks per bit at 9600 baud
    localparam int NUM_RANDOM = 32;

    logic clk, rst_n, trmt, DATA_LINE, tx_done, rdy, clr_rdy;
    logic [7:0] tx_data, rx_data;

    UART_tx i_TX (
        .clk(clk),
        .rst_n(rst_n),
        .trmt(trmt),
        .TX(DATA_LINE),
        .tx_data(tx_data),
        .tx_done(tx_done)
    );

    UART_rx i_RX (
        .clk(clk),
        .rst_n(rst_n),
        .RX(DATA_LINE),
        .clr_rdy(clr_rdy),
        .rx_data(rx_data),
        .rdy(rdy)
    );

    always #HALF_CLK clk = ~clk;

    int num_checks = 0;

    // all 0s/1s, alternating, single bit set/cleared at each end
    logic [7:0] edge_bytes[8] = '{8'h00, 8'hFF, 8'h55, 8'hAA, 8'h01, 8'h80, 8'hFE, 8'h7F};

    ////////////////////////////////////////////////////////////////
    // Helpers
    ////////////////////////////////////////////////////////////////

    // Stop the sim on the first failing check
    task automatic check(input logic cond, input string msg);
        num_checks++;
        if (!cond) begin
            $display("ERROR @ %0t: %s", $time, msg);
            $stop();
        end
    endtask

    // Wait for sig to equal val, failing if it takes more than max_cycles
    task automatic wait_for(ref logic sig, input logic val, input int max_cycles,
                            input string name);
        int cycles = 0;
        while (sig !== val) begin
            @(negedge clk);
            if (++cycles > max_cycles) begin
                $display("ERROR @ %0t: timed out waiting for %s == %b", $time, name, val);
                $stop();
            end
        end
    endtask

    // Pulse trmt for one clock and check that the transmitter started
    task automatic start_tx(input logic [7:0] data);
        @(negedge clk);
        tx_data = data;
        trmt = 1;
        @(negedge clk);
        trmt = 0;
        check(DATA_LINE === 0, "TX should drop to the start bit right after trmt");
        check(tx_done === 0, "tx_done should clear when a transmission starts");
    endtask

    // Watch the TX line on its own: sample the middle of each bit and compare it to
    // {stop, data (LSB first), start}. Call this right after start_tx returns.
    task automatic check_frame(input logic [7:0] data);
        logic [9:0] frame = {1'b1, data, 1'b0};
        repeat (BAUD / 2) @(negedge clk);
        for (int i = 0; i < 10; i++) begin
            check(DATA_LINE === frame[i], $sformatf("TX bit %0d of frame %h: expected %b, got %b",
                                                    i, data, frame[i], DATA_LINE));
            check(tx_done === 0, $sformatf("tx_done went high early, during bit %0d", i));
            if (i > 0 && i < 9)  // rdy clears on the start bit and sets during the stop bit
                check(rdy === 0, $sformatf("rdy should be low while receiving bit %0d", i));
            if (i < 8) repeat (BAUD) @(negedge clk);
            else if (i == 8) begin
                // rdy must not rise until ~mid stop bit, proving RX samples mid-bit
                repeat (BAUD - 20) @(negedge clk);
                check(rdy === 0, "rdy rose too early: RX is not sampling the middle of each bit");
                repeat (20) @(negedge clk);
            end
        end
    endtask

    // After the frame: rdy rises (middle of stop bit), then tx_done rises (end of stop bit)
    task automatic check_complete(input logic [7:0] data);
        wait_for(rdy, 1, 20, "rdy");  // and must rise by ~mid stop bit
        check(rx_data === data, $sformatf("rx_data: expected %h, got %h", data, rx_data));
        check(tx_done === 0, "rdy should rise before tx_done (mid vs end of stop bit)");
        wait_for(tx_done, 1, BAUD, "tx_done");
        check(rdy === 1, "rdy should stay high until clr_rdy or the next start bit");
        check(rx_data === data, "rx_data changed after rdy was set");
        check(DATA_LINE === 1, "TX should idle high after the stop bit");
    endtask

    // A complete transfer: start, check every bit on the line, check what was received
    task automatic send_byte(input logic [7:0] data);
        start_tx(data);
        check_frame(data);
        check_complete(data);
    endtask

    task automatic pulse_clr_rdy();
        @(negedge clk);
        clr_rdy = 1;
        @(negedge clk);
        clr_rdy = 0;
        check(rdy === 0, "clr_rdy should knock rdy down");
    endtask

    ////////////////////////////////////////////////////////////////
    // Tests
    ////////////////////////////////////////////////////////////////

    initial begin
        clk = 0;
        rst_n = 0;
        trmt = 0;
        clr_rdy = 0;
        tx_data = 0;

        repeat (5) @(negedge clk);

        $display("Test 1: values during reset");
        check(DATA_LINE === 1, "TX should be high during reset");
        check(tx_done === 0, "tx_done should be low during reset");
        check(rdy === 0, "rdy should be low during reset");
        rst_n = 1;

        $display("Test 2: line stays idle with no trmt");
        repeat (2 * BAUD) @(negedge clk);
        check(DATA_LINE === 1, "TX should idle high");
        check(rdy === 0, "rdy should not go high without a frame");

        $display("Test 3: send one byte, check each bit on the line");
        send_byte(8'hA5);

        $display("Test 4: rdy and tx_done stay high while idle");
        repeat (3 * BAUD) @(negedge clk);
        check(rdy === 1, "rdy dropped on its own");
        check(tx_done === 1, "tx_done dropped on its own");
        check(rx_data === 8'hA5, "rx_data changed while idle");

        $display("Test 5: clr_rdy knocks rdy down, and only rdy");
        pulse_clr_rdy();
        check(tx_done === 1, "clr_rdy should not affect tx_done");
        check(rx_data === 8'hA5, "clr_rdy should not affect rx_data");
        repeat (10) @(negedge clk);
        check(rdy === 0, "rdy came back without a new frame");

        $display("Test 6: edge-case bytes");
        foreach (edge_bytes[i]) begin
            send_byte(edge_bytes[i]);
            pulse_clr_rdy();
        end

        $display("Test 7: next start bit clears rdy without clr_rdy");
        send_byte(8'h3C);
        check(rdy === 1, "rdy should be high before the next frame");
        start_tx(8'hC3);
        wait_for(rdy, 0, 5, "rdy (cleared by start bit)");
        check_frame(8'hC3);
        check_complete(8'hC3);

        $display("Test 8: clr_rdy during a frame does not disturb it");
        start_tx(8'h69);
        fork
            check_frame(8'h69);
            begin
                repeat (4 * BAUD) @(negedge clk);
                clr_rdy = 1;
                repeat (BAUD) @(negedge clk);  // hold it for a full bit
                clr_rdy = 0;
            end
        join
        check_complete(8'h69);
        pulse_clr_rdy();

        $display("Test 9: trmt during a frame is ignored, tx_data is latched at start");
        start_tx(8'h81);
        fork
            check_frame(8'h81);
            begin
                repeat (3 * BAUD + 17) @(negedge clk);
                tx_data = 8'h7E;  // changing tx_data mid-frame must not affect TX
                trmt = 1;
                @(negedge clk);
                trmt = 0;
            end
        join
        check_complete(8'h81);
        repeat (2 * BAUD) @(negedge clk);  // a second frame would have started by now
        check(DATA_LINE === 1, "trmt during a frame started a second frame");
        check(rx_data === 8'h81, "a second byte was received");
        pulse_clr_rdy();

        $display("Test 10: back-to-back frames (trmt as soon as tx_done)");
        for (int i = 0; i < 4; i++) begin
            send_byte(8'h11 * (i + 1));  // send_byte returns on the tx_done edge
        end
        pulse_clr_rdy();

        $display("Test 11: reset in the middle of a frame");
        start_tx(8'h00);
        repeat (4 * BAUD + 100) @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        check(DATA_LINE === 1, "TX should go high on reset mid-frame");
        check(tx_done === 0, "tx_done should be low after reset");
        check(rdy === 0, "rdy should be low after reset");
        rst_n = 1;
        repeat (2 * BAUD) @(negedge clk);
        check(rdy === 0, "receiver finished a frame that was cut off by reset");
        send_byte(8'hE7);  // both sides recover cleanly
        pulse_clr_rdy();

        $display("Test 12: %0d random bytes", NUM_RANDOM);
        for (int i = 0; i < NUM_RANDOM; i++) begin
            automatic logic [7:0] data = $urandom();
            send_byte(data);
            if ($urandom_range(1)) pulse_clr_rdy();  // sometimes let the start bit clear rdy
        end

        $display("YAHOO!! All tests passed (%0d checks)", num_checks);
        $stop();
    end

endmodule
