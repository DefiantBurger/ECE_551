module UART_rx(
    input clk, rst_n, RX, clr_rdy,
    output logic [7:0] rx_data,
    output rdy
);
    // 50MHz / 9600 baud = 5208
    logic [12:0] counter;

    logic receive_next_bit;

    // Synchronize asynchronous RX input
    logic RX_sync_1, RX_sync_2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            RX_sync_1 <= 1;
            RX_sync_2 <= 1;
        end else begin
            RX_sync_1 <= RX;
            RX_sync_2 <= RX_sync_1;
        end
    end

    assign receive_next_bit = (counter == 0);

    typedef enum { NOT_RECEIVING, RECEIVING } e_state;

    e_state state;
    e_state next_state;

    logic [3:0] received_bits;
    logic set_rdy;
    logic [8:0] rx_buffer;

    // FSM state logic
    always_comb begin
        next_state = state;
        set_rdy = 0;

        if (state == NOT_RECEIVING && !RX_sync_2)
            next_state = RECEIVING;
        else if (state == RECEIVING &&
                 receive_next_bit && 
                 received_bits == 4'd9) begin
            next_state = NOT_RECEIVING;
            set_rdy = 1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= NOT_RECEIVING;
            counter <= 0;
            rx_data <= 0;
            rx_buffer <= 0;
            received_bits <= 0;
        end else begin
            state <= next_state;

            if (state == NOT_RECEIVING) begin
                counter <= 0; // no latches in this household

                if (!RX_sync_2) begin // started receiving
                    counter <= 13'd2604; // sample middle because we're cool
                    received_bits <= 0;
                end
            end else begin // in the RECEIVING state
                if (counter != 0)
                    counter <= counter - 1;
                else begin
                    // Check if we're just getting started
                    if (received_bits == 0) begin // not started
                        if (!RX_sync_2) begin // should start
                            received_bits <= 1;
                            counter <= 13'd5207;
                        end else begin // shouldn't start
                            state <= NOT_RECEIVING;
                        end
                    end else begin // we've been started
                        rx_buffer <= {RX_sync_2, rx_buffer[8:1]};
                        received_bits <= received_bits + 1;
                        counter <= 13'd5207;

                        if (received_bits == 4'd8) begin
                            // all done :D
                            rx_data <= {RX_sync_2, rx_buffer[8:2]};
                            counter <= 0;
                        end
                    end
                end
            end
        end
    end

    sr_ff i_RDY(
        .clk(clk),
        .rst_n(rst_n),
        .set(set_rdy),
        .reset(clr_rdy),
        .q(rdy)
    );

endmodule
