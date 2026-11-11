// SM for one conversion: 1st SPI transaction sends the channel,
// 2nd one reads back the result
module A2D_Intf_SM (
    input rst_n,
    clk,
    nxt,  // start a conversion
    done,  // from SPI_main, current transaction finished
    output logic wrt,  // kicks off a SPI transaction
    update  // conversion done, load holding reg + bump round robin
);
    // IDLE:   waiting for nxt
    // FIRST:  1st transaction in flight (sending channel, MISO ignored)
    // WAIT:   1 clk gap between the two transactions
    // SECOND: 2nd transaction in flight (MOSI ignored, reading result)
    typedef enum logic [1:0] {
        IDLE,
        FIRST,
        WAIT,
        SECOND
    } state_t;

    state_t state, next_state;

    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always_comb begin
        // default outputs, so nothing gets inferred as a latch
        wrt = 0;
        update = 0;
        next_state = IDLE;

        case (state)
            IDLE: begin
                if (nxt) begin
                    wrt = 1;
                    next_state = FIRST;
                end
            end
            FIRST: begin
                if (done) next_state = WAIT;
                else next_state = FIRST;
            end
            WAIT: begin
                // spec wants the 2 transactions separated by 1 system clk,
                // also gives the ADC the new channel before the 2nd read
                wrt = 1;
                next_state = SECOND;
            end
            SECOND: begin
                // rd_data now holds the result, so load it
                if (done) begin
                    update = 1;
                    next_state = IDLE;
                end else next_state = SECOND;
            end
            default: begin
                // keep defaults
            end
        endcase
    end
endmodule

// Round robins through the 4 A2D channels, one conversion per nxt pulse
module A2D_intf (
    input clk,  // 50MHz
    rst_n,
    nxt,  // do a conversion on the next channel
    MISO,  // from ADC128S
    output logic [11:0] lft_ld,  // last result on each channel
    rght_ld,
    steer_pot,
    batt,
    output SS_n,  // SPI to ADC128S
    SCLK,
    MOSI
);

    // lft(0), rght(4), steer(5), batt(6)
    localparam logic [2:0] CHNLS[4] = '{3'd0, 3'd4, 3'd5, 3'd6};

    logic [15:0] rd_data;
    logic [15:0] wt_data;
    logic wrt, done, update;
    logic [2:0] channel;
    logic en_lft, en_rght, en_steer, en_batt;  // holding register enables

    A2D_Intf_SM i_SM (
        .rst_n(rst_n),
        .clk(clk),
        .nxt(nxt),
        .done(done),
        .wrt(wrt),
        .update(update)
    );

    // same SPI_main as before, does all the SS_n/SCLK/MOSI/MISO work
    SPI_main i_SPI (
        .rst_n(rst_n),
        .clk(clk),
        .MISO(MISO),
        .wrt(wrt),
        .wt_data(wt_data),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .done(done),
        .rd_data(rd_data)
    );

    // round robin counter, moves to the next channel once a conversion finishes
    logic [1:0] counter;

    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) counter <= '0;
        else if (update) counter <= counter + 1;  // wraps 3 -> 0 on its own
    end

    // pick the channel and which register gets the result
    always_comb begin
        channel  = CHNLS[0];
        en_lft   = 0;
        en_rght  = 0;
        en_steer = 0;
        en_batt  = 0;

        case (counter)
            2'b00: begin
                channel = CHNLS[0];
                en_lft  = update;
            end
            2'b01: begin
                channel = CHNLS[1];
                en_rght = update;
            end
            2'b10: begin
                channel  = CHNLS[2];
                en_steer = update;
            end
            2'b11: begin
                channel = CHNLS[3];
                en_batt = update;
            end
            default: begin
                // keep defaults
            end
        endcase
    end

    // conversion command: upper 2 bits 0, channel in [13:11], lower 11 bits 0.
    // sent on both transactions, the ADC just ignores it the 2nd time
    assign wt_data = {2'b00, channel[2:0], 11'h00};

    // holding registers, only the one for the current channel loads on update.
    // ADC is 12 bit, so the top 4 bits of rd_data are just 0s
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) lft_ld <= '0;
        else if (en_lft) lft_ld <= rd_data[11:0];
    end

    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) rght_ld <= '0;
        else if (en_rght) rght_ld <= rd_data[11:0];
    end

    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) steer_pot <= '0;
        else if (en_steer) steer_pot <= rd_data[11:0];
    end

    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) batt <= '0;
        else if (en_batt) batt <= rd_data[11:0];
    end

endmodule
