// Control FSM for UART_rx
module UART_rx_SM (
    input clk,
    rst_n,
    RX_sync,
    baud_done,
    done9,
    output logic start,
    receiving,
    shift,
    set_rdy
);
    typedef enum logic {
        IDLE,
        RECEIVING
    } state_t;
    state_t state, next_state;

    // State flip flop
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end

    // Next state & output logic
    always_comb begin
        next_state = state;

        start = 0;
        receiving = 0;
        shift = 0;
        set_rdy = 0;

        case (state)
            IDLE: begin
                // line idles high; a low means the start bit has begun
                if (!RX_sync) begin
                    next_state = RECEIVING;
                    start = 1;
                end
            end
            RECEIVING: begin
                receiving = 1;
                if (baud_done) begin
                    shift = 1;
                    // 10th shift samples the stop bit; byte is complete
                    if (done9) begin
                        next_state = IDLE;
                        set_rdy = 1;
                    end
                end
            end
            default: next_state = IDLE;
        endcase
    end
endmodule

module UART_rx (
    input clk,
    rst_n,
    RX,
    clr_rdy,
    output logic [7:0] rx_data,
    output logic rdy
);
    // 50 MHz / 9600 baud ~= 5208 clocks per bit
    localparam logic [12:0] BAUD_CYCLES = 13'd5207;
    localparam logic [12:0] HALF_BAUD_CYCLES = 13'd2603;  // first sample mid start bit

    logic RX_sync, baud_done, done9;  // SM inputs
    logic start, receiving, shift, set_rdy;  // SM outputs
    UART_rx_SM i_SM (
        .clk(clk),
        .rst_n(rst_n),
        .RX_sync(RX_sync),
        .baud_done(baud_done),
        .done9(done9),
        .start(start),
        .receiving(receiving),
        .shift(shift),
        .set_rdy(set_rdy)
    );

    // Double flop async RX for metastability; preset since line idles high
    logic RX_ff1;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            RX_ff1  <= 1;
            RX_sync <= 1;
        end else begin
            RX_ff1  <= RX;
            RX_sync <= RX_ff1;
        end
    end

    // rdy: knocked down by next start bit or clr_rdy, set when byte is complete
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) rdy <= 0;
        else if (start | clr_rdy) rdy <= 0;
        else if (set_rdy) rdy <= 1;
        else rdy <= rdy;
    end

    // Counts shifts; done9 flags the 10th (final) shift
    logic [3:0] bit_cnt;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) bit_cnt <= 0;
        else bit_cnt <= start ? 0 : bit_cnt + shift;
    end

    assign done9 = (bit_cnt == 4'd9);

    // Baud counter: half period on start, full period after each shift
    logic [12:0] baud_cnt;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) baud_cnt <= 0;
        else if (start) baud_cnt <= HALF_BAUD_CYCLES;
        else if (shift) baud_cnt <= BAUD_CYCLES;
        else if (receiving) baud_cnt <= baud_cnt - 1;
        else baud_cnt <= baud_cnt;
    end

    assign baud_done = (baud_cnt == 0);

    // Shift in LSB first; after 10 shifts the start bit has fallen off the end
    logic [8:0] rx_shft_reg;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) rx_shft_reg <= 0;
        else if (shift) rx_shft_reg <= {RX_sync, rx_shft_reg[8:1]};
        else rx_shft_reg <= rx_shft_reg;
    end

    assign rx_data = rx_shft_reg[7:0];

endmodule
