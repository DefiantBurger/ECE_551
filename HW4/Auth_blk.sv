// Authentication FSM: powers up on 'G', powers down once 'S' was last received and rider is off
module auth_SM (
    input clk,
    rst_n,
    input [7:0] rx_data,
    input rx_rdy,
    rider_off,
    output logic clr_rx_rdy,
    pwr_up
);
    localparam logic [7:0] GO   = 8'h47;  // 'G'
    localparam logic [7:0] STOP = 8'h53;  // 'S'

    typedef enum logic [1:0] {
        OFF,   // powered down
        PWR1,  // powered up, last command was 'G'
        PWR2   // powered up, got 'S', waiting for rider to step off
    } state_t;
    state_t state, next_state;

    // State flip flop
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) state <= OFF;
        else state <= next_state;
    end

    // Next state & output logic
    always_comb begin
        next_state = state;
        clr_rx_rdy = rx_rdy;  // always consume a received byte
        pwr_up = (state != OFF);

        case (state)
            OFF: if (rx_rdy && rx_data == GO) next_state = PWR1;
            PWR1: if (rx_rdy && rx_data == STOP) next_state = (rider_off ? OFF : PWR2);
            PWR2:
            if (rx_rdy && rx_data == GO) next_state = PWR1;  // re-authorized
            else if (rider_off) next_state = OFF;
            default: next_state = OFF;
        endcase
    end
endmodule

module Auth_blk (
    input  clk,
    rst_n,
    RX,
    rider_off,
    output pwr_up
);

    logic [7:0] rx_data;
    logic rx_rdy, clr_rx_rdy;

    UART_rx i_UART_rx (
        .clk(clk),
        .rst_n(rst_n),
        .RX(RX),
        .clr_rdy(clr_rx_rdy),
        .rx_data(rx_data),
        .rdy(rx_rdy)
    );

    auth_SM i_auth_SM (
        .clk(clk),
        .rst_n(rst_n),
        .rx_data(rx_data),
        .rx_rdy(rx_rdy),
        .rider_off(rider_off),
        .clr_rx_rdy(clr_rx_rdy),
        .pwr_up(pwr_up)
    );

endmodule
