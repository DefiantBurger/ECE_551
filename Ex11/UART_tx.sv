module UART_tx (
    input clk, rst_n, trmt,
    input [7:0] tx_data,
    output TX, tx_done
);
    logic [12:0] counter;
    logic [12:0] next_count;

    always_ff @( negedge rst_n or posedge trmt or posedge clk) begin
        if (!rst_n)
            counter <= '0;
        else if (trmt)
            counter <= '0;
        else
            counter <= next_count;
    end

    // 50MHz / 9600 baud = 5208
    // 5208 -> 13 bits

    logic send_next_bit;
    always_comb begin
        if (counter < 13'd5208) begin
            next_count = counter + 1;
            send_next_bit = '0;
        end else begin
            next_count = '0;
            send_next_bit = '1;
        end
    end

    logic [8:0] tx_buffer;
    assign TX = tx_buffer[0];
    always_ff @( negedge rst_n or posedge trmt or posedge send_next_bit ) begin
        if (!rst_n)
            tx_buffer <= '0;
        else if (trmt)
            tx_buffer <= {tx_data, 1'b0};
        else
            tx_buffer <= {1'b1, tx_buffer[8:1]};
    end

    logic [3:0] bits_sent;
    always_ff @( negedge rst_n or posedge send_next_bit ) begin
        if (!rst_n)
            bits_sent <= '0;
        else
            bits_sent <= bits_sent + 1;
    end

    sr_ff i_tx_done_flop(
        .clk(clk), 
        .rst_n(rst_n), 
        .set(bits_sent == 4'd9), 
        .reset(trmt),
        .q(tx_done)
    );

endmodule