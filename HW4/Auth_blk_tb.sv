// Self-checking testbench for Auth_blk: drives RX with UART_tx and walks every state/arc of auth_SM
module Auth_blk_tb;
    localparam int HALF_CLK = 10;  // 50 MHz clock -> 20 ns period
    localparam int BAUD = 5208;  // clocks per bit at 9600 baud
    localparam int FRAME = 10 * BAUD;  // start + 8 data + stop

    localparam logic [7:0] GO = 8'h47;  // 'G'
    localparam logic [7:0] STOP = 8'h53;  // 'S'

    logic clk, rst_n, trmt, tx_done, TX_RX, rider_off, pwr_up;
    logic [7:0] tx_data;

    UART_tx i_TX (
        .clk(clk),
        .rst_n(rst_n),
        .trmt(trmt),
        .tx_data(tx_data),
        .TX(TX_RX),
        .tx_done(tx_done)
    );

    Auth_blk iDUT (
        .clk(clk),
        .rst_n(rst_n),
        .RX(TX_RX),
        .rider_off(rider_off),
        .pwr_up(pwr_up)
    );

    always #HALF_CLK clk = ~clk;
    initial clk = 0;

    ////////////////////////////////////////////////////////////////
    // Helpers
    ////////////////////////////////////////////////////////////////

    // Stop the sim on the first failing check
    task automatic check(input logic cond, input string msg);
        if (!cond) begin
            $display("ERROR @ %0t: %s", $time, msg);
            $stop();
        end
    endtask

    // Check pwr_up and the internal SM state together
    task automatic check_state(input string exp_state, input logic exp_pwr, input string msg);
        check(iDUT.i_auth_SM.state.name() == exp_state, $sformatf(
              "%s: expected state %s, got %s", msg, exp_state, iDUT.i_auth_SM.state.name()));
        check(pwr_up === exp_pwr, $sformatf("%s: expected pwr_up=%b, got %b", msg, exp_pwr, pwr_up
              ));
    endtask

    // Transmit one byte, then give UART_rx + auth_SM a few clocks to react
    task automatic send_byte(input logic [7:0] data);
        @(negedge clk);
        tx_data = data;
        trmt = 1;
        @(negedge clk);
        trmt = 0;

        // rx sets rdy half a bit before tx_done, so the SM has already reacted by now
        fork : send_fork
            begin
                @(posedge tx_done);
            end
            begin
                repeat (FRAME + BAUD) @(negedge clk);
                $display("ERROR @ %0t: timed out sending 0x%h", $time, data);
                $stop();
            end
        join_any
        disable send_fork;
        repeat (5) @(negedge clk);

        // SM must always consume the byte so rdy doesn't stay set
        check(iDUT.rx_rdy === 0, $sformatf("rx_rdy not cleared after 0x%h", data));
    endtask

    // Change rider_off and let the SM settle
    task automatic set_rider_off(input logic val);
        @(negedge clk);
        rider_off = val;
        repeat (3) @(negedge clk);
    endtask

    ////////////////////////////////////////////////////////////////
    // Test sequence
    ////////////////////////////////////////////////////////////////
    initial begin
        rst_n = 0;
        trmt = 0;
        tx_data = 0;
        rider_off = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
        repeat (2) @(negedge clk);
        check_state("OFF", 0, "after reset");

        // OFF self-loops: 'S', junk byte, and rider_off toggling don't power up
        send_byte(STOP);
        check_state("OFF", 0, "OFF + 'S'");
        send_byte(8'hA5);
        check_state("OFF", 0, "OFF + junk");
        set_rider_off(1);
        set_rider_off(0);
        check_state("OFF", 0, "OFF + rider_off toggle");

        // OFF -> PWR1 on 'G'
        send_byte(GO);
        check_state("PWR1", 1, "OFF + 'G'");

        // PWR1 self-loops: repeated 'G', junk, and rider_off without 'S'
        send_byte(GO);
        check_state("PWR1", 1, "PWR1 + 'G'");
        send_byte(8'h00);
        check_state("PWR1", 1, "PWR1 + junk");
        set_rider_off(1);
        check_state("PWR1", 1, "PWR1 + rider_off (no 'S')");
        set_rider_off(0);

        // PWR1 -> PWR2 on 'S' with rider still on
        send_byte(STOP);
        check_state("PWR2", 1, "PWR1 + 'S', rider on");

        // PWR2 self-loops: repeated 'S' and junk while rider stays on
        send_byte(STOP);
        check_state("PWR2", 1, "PWR2 + 'S'");
        send_byte(8'hFF);
        check_state("PWR2", 1, "PWR2 + junk");

        // PWR2 -> PWR1 on 'G' (re-authorized), rider_off must no longer power down
        send_byte(GO);
        check_state("PWR1", 1, "PWR2 + 'G'");
        set_rider_off(1);
        check_state("PWR1", 1, "re-authorized + rider_off");
        set_rider_off(0);

        // PWR1 -> PWR2 -> OFF when rider steps off
        send_byte(STOP);
        check_state("PWR2", 1, "PWR1 + 'S' (2nd)");
        set_rider_off(1);
        check_state("OFF", 0, "PWR2 + rider_off");

        // PWR1 -> OFF directly on 'S' when rider already off
        send_byte(GO);
        check_state("PWR1", 1, "OFF + 'G' with rider off");
        send_byte(STOP);
        check_state("OFF", 0, "PWR1 + 'S', rider off");
        set_rider_off(0);

        // Async reset from a powered state returns to OFF
        send_byte(GO);
        check_state("PWR1", 1, "OFF + 'G' before reset");
        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        check_state("OFF", 0, "reset from PWR1");

        $display("YAHOO! All tests passed.");
        $stop();
    end

endmodule
