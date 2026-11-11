// Control FSM for SPI_main
module SPI_SM (
    input clk,
    rst_n,
    wrt,
    done15,
    shft_imm,
    output logic shft,
    ld_SCLK,
    init,
    set_done
);
    typedef enum logic [1:0] {
        IDLE,
        FRONT_PORCH,
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

        shft = 0;
        ld_SCLK = 0;
        init = 0;
        set_done = 0;

        case (state)
            IDLE: begin
                ld_SCLK = 1;  // hold SCLK_div at 1011 so SCLK idles high
                if (wrt) begin
                    next_state = FRONT_PORCH;
                    init = 1;
                end
            end
            FRONT_PORCH: begin
                // first SCLK fall: don't shift, MOSI already holds C15
                if (shft_imm) next_state = TRANSMITTING;
            end
            TRANSMITTING: begin
                if (shft_imm) begin
                    shft = 1;
                    // final shift as SS_n rises; reload SCLK_div to block the last fall
                    if (done15) begin
                        next_state = IDLE;
                        ld_SCLK = 1;
                        set_done = 1;
                    end
                end
            end
            default: next_state = IDLE;
        endcase
    end
endmodule

module SPI_main (
    input clk,
    rst_n,
    MISO,
    wrt,
    input [15:0] wt_data,
    output logic SS_n,
    SCLK,
    MOSI,
    done,
    output logic [15:0] rd_data
);

    logic done15, smpl, shft_imm;  // additional SM inputs
    logic shft, ld_SCLK, init, set_done;  // outputs
    SPI_SM i_SM (
        .clk(clk),
        .rst_n(rst_n),
        .wrt(wrt),
        .done15(done15),
        .shft_imm(shft_imm),
        .shft(shft),
        .ld_SCLK(ld_SCLK),
        .init(init),
        .set_done(set_done)
    );

    // SS_n (preset) and done (reset) are flopped to avoid glitches
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            SS_n <= 1;
            done <= 0;
        end else if (init) begin
            SS_n <= 0;
            done <= 0;
        end else if (set_done) begin
            SS_n <= 1;
            done <= 1;
        end else begin
            SS_n <= SS_n;
            done <= done;
        end
    end

    // Counts shifts; done15 flags the 16th (final) shift
    logic [3:0] bit_cntr;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) bit_cntr <= 0;
        else bit_cntr <= init ? 0 : bit_cntr + shft;
    end

    assign done15 = &bit_cntr;

    // SCLK divider: SCLK = clk/16; 1011 start creates the front porch
    logic [3:0] SCLK_div;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) SCLK_div <= 4'b1011;  // almost full
        else if (ld_SCLK) SCLK_div <= 4'b1011;
        else SCLK_div <= SCLK_div + 1;
    end

    assign SCLK = SCLK_div[3];

    assign smpl = (SCLK_div == 4'b0111);  // SCLK rises next clk
    assign shft_imm = (SCLK_div == 4'b1111);  // SCLK falls next clk

    // Sample MISO on SCLK rise, shift it in on the following fall
    logic MISO_smpl;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) MISO_smpl <= 0;
        else MISO_smpl <= smpl ? MISO : MISO_smpl;
    end

    // Shared TX/RX shift register: MSB out on MOSI, MISO_smpl in at LSB
    logic [15:0] shft_reg;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) shft_reg <= 0;
        else if (init) shft_reg <= wt_data;
        else if (shft) shft_reg <= {shft_reg[14:0], MISO_smpl};
        else shft_reg <= shft_reg;
    end
    assign MOSI = shft_reg[15];
    assign rd_data = shft_reg;


endmodule
