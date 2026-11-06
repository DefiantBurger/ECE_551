// Control FSM for UART_tx
module UART_tx_SM (
    input clk,
    rst_n,
    trmt,
    baud_done,
    done9,
    output logic init,
    transmitting,
    shift,
    set_done
);
    typedef enum logic {
        IDLE,
        TRANSMITTING
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

        init = 0;
        transmitting = 0;
        shift = 0;
        set_done = 0;

        case (state)
            IDLE: begin
                if (trmt) begin
                    next_state = TRANSMITTING;
                    init = 1;
                end
            end
            TRANSMITTING: begin
                transmitting = 1;
                if (baud_done) begin
                    shift = 1;
                    // 10th shift ends the stop bit
                    if (done9) begin
                        next_state = IDLE;
                        set_done = 1;
                    end
                end
            end
            default: next_state = IDLE;
        endcase
    end
endmodule

module UART_tx (
    input clk,
    rst_n,
    trmt,
    input [7:0] tx_data,
    output logic TX,
    tx_done
);
    // 50 MHz / 9600 baud ~= 5208 clocks per bit
    localparam logic [12:0] BAUD_CYCLES = 13'd5207;

    logic baud_done, done9;  // SM inputs
    logic init, transmitting, shift, set_done;  // SM outputs
    UART_tx_SM i_SM (
        .clk(clk),
        .rst_n(rst_n),
        .trmt(trmt),
        .baud_done(baud_done),
        .done9(done9),
        .init(init),
        .transmitting(transmitting),
        .shift(shift),
        .set_done(set_done)
    );

    // tx_done is flopped to avoid glitches
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) tx_done <= 0;
        else if (init) tx_done <= 0;
        else if (set_done) tx_done <= 1;
        else tx_done <= tx_done;
    end

    // Counts shifts; done9 flags the 10th (final) shift
    logic [3:0] bit_cnt;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) bit_cnt <= 0;
        else bit_cnt <= init ? 0 : bit_cnt + shift;
    end

    assign done9 = (bit_cnt == 4'd9);

    // Baud counter: reload on start/shift, count down while transmitting
    logic [12:0] baud_cnt;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) baud_cnt <= 0;
        else if (init | shift) baud_cnt <= BAUD_CYCLES;
        else if (transmitting) baud_cnt <= baud_cnt - 1;
        else baud_cnt <= baud_cnt;
    end

    assign baud_done = (baud_cnt == 0);

    // {data, start} shifted out LSB first; 1s shift in to form the stop bit / idle
    logic [8:0] tx_shft_reg;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) tx_shft_reg <= '1;
        else if (init) tx_shft_reg <= {tx_data, 1'b0};
        else if (shift) tx_shft_reg <= {1'b1, tx_shft_reg[8:1]};
        else tx_shft_reg <= tx_shft_reg;
    end

    assign TX = tx_shft_reg[0];

endmodule
