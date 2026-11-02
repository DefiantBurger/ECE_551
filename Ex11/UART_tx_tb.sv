module UART_tx_tb;

    logic clk, rst_n, trmt, TX, tx_done;
    logic [7:0] tx_data;

    UART_tx iDUT(
        .clk(clk), 
        .rst_n(rst_n), 
        .trmt(trmt), 
        .TX(TX), 
        .tx_data(tx_data),
        .tx_done(tx_done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = '0;
        rst_n = '0;
        trmt = '0;
        tx_data = 8'b10011010;

        #10

        rst_n = '1;

        #10

        trmt = '1;

        #5

        trmt = '0;

        #(5 * 6000 * 30)

        tx_data = 8'b11011101;
        trmt = '1;

        #5

        trmt = '0;

        #(5 * 6000 * 30)

        $stop();
    end

endmodule