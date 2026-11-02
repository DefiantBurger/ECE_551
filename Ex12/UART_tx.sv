module UART_tx (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       trmt,
    input  logic [7:0] tx_data,
    output logic       TX,
    output logic       tx_done
);

    // 50 MHz / 9600 baud ~= 5208 clock cycles
    localparam logic [12:0] BAUD_COUNT = 13'd5207;

    logic [12:0] counter;
    logic [8:0] tx_buffer;
    logic [3:0] bits_sent;
    logic transmitting;

    // Counter reaches zero when it is time to send the next bit
    logic baud_tick;
    assign baud_tick = (counter == 0);

    // TX = LSB or high if not transmitting
    assign TX = transmitting ? tx_buffer[0] : 1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            tx_buffer <= '1;
            bits_sent <= 0;
            transmitting <= 0;
            tx_done <= 0;
        end else begin

            // Start sending data
            if (trmt && !transmitting) begin
                tx_buffer <= {tx_data, 1'b0};
                counter <= BAUD_COUNT;
                bits_sent <= 0;
                transmitting <= 1;
                tx_done <= 0;
            end else if (transmitting) begin
                if (baud_tick) begin
                    counter <= BAUD_COUNT;

                    if (bits_sent == 4'd9) begin
                        // all done :D
                        transmitting <= 0;
                        tx_done <= 1;
                    end else begin
                        tx_buffer <= {1'b1, tx_buffer[8:1]};
                        bits_sent <= bits_sent + 1;
                    end
                end else begin
                    counter <= counter - 1;
                end
            end else begin
                counter <= 0;
            end

        end
    end

endmodule