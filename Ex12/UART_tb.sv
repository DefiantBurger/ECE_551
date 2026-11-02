module UART_tb;
    localparam CLK = 10;  // 50 MHz clock -> 20 ns period

    logic clk, rst_n, trmt, DATA_LINE, tx_done, rdy, clr_rdy;
    logic [7:0] tx_data, rx_data;

    UART_tx i_TX(
        .clk(clk),
        .rst_n(rst_n),
        .trmt(trmt),
        .TX(DATA_LINE),
        .tx_data(tx_data),
        .tx_done(tx_done)
    );

    UART_rx i_RX(
        .clk(clk),
        .rst_n(rst_n),
        .RX(DATA_LINE),
        .clr_rdy(clr_rdy),
        .rx_data(rx_data),
        .rdy(rdy)
    );

    always #CLK clk = ~clk;

    // https://chipverify.com/systemverilog/systemverilog-functions-tasks#tasks
    task test_send_byte(input logic [7:0] test_data,
                        input integer test_num);
        begin
            @(negedge clk);
            tx_data = test_data;
            trmt = 1;

            @(negedge clk);
            trmt = 0;

            // Wait for tx and rx to complete.
            wait (tx_done == 1);
            wait (rdy == 1);

            @(negedge clk);

            if (rx_data !== test_data) begin
                $display("Test %0d failed: expected %h, got %h",
                         test_num, test_data, rx_data);
                $stop;
            end else begin
                $display("Test %0d passed!", test_num);
            end

            // Clear rdy before the next test
            clr_rdy = 1;
            @(negedge clk);
            clr_rdy = 0;
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        trmt = 0;
        clr_rdy = 0;
        tx_data = 0;

        repeat (5) @(negedge clk);
        rst_n = 1;

        test_send_byte(8'b10011010, 1);
        test_send_byte(8'b11111011, 2);
        test_send_byte(8'b00010010, 3);
        test_send_byte(8'b11110000, 4);
        test_send_byte(8'b00001111, 5);
        test_send_byte(8'b11111111, 6);
        test_send_byte(8'b00000000, 7);

        $display("All tests passed!");
        $stop();
    end
endmodule