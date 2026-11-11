// DE0-Nano wrapper: does ~100 A2D conversions a second and shows the
// top 8 bits of one result on the LEDs. SEL button cycles which one.
module A2D_test (
    clk,
    RST_n,
    SEL,
    LED,
    SCLK,
    SS_n,
    MOSI,
    MISO
);

    input clk, RST_n;  // clk and unsynched reset from PB
    input SEL;  // from 2nd PB, cycle through outputs
    input MISO;  // from A2D

    output logic [7:0] LED;  // upper 8 bits of the selected result
    output SS_n;  // active low slave select to A2D
    output SCLK;  // SCLK to A2D SPI
    output MOSI;  // channel commands to A2D

    ////////////////////////////////////////////////////////////
    // Declare any needed internal registers (like counters) //
    //////////////////////////////////////////////////////////
    logic [18:0] nxt_counter;
    logic [1:0] out_sel_counter;

    ///////////////////////////////////////////////////////
    // Declare any needed internal signals as type wire //
    /////////////////////////////////////////////////////
    wire nxt, rst_n, en_2bit;
    wire [11:0] lft_ld, rght_ld, steer_pot, batt;

    // kick off a conversion every 2^19 clocks (~10ms at 50MHz, so ~100/s).
    // full is only high for 1 clk, so nxt is a clean pulse
    assign nxt = &nxt_counter;

    //////////////////////////////////////////////////
    // Infer 19-bit counter to set conversion rate //
    ////////////////////////////////////////////////
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) nxt_counter <= 0;
        else nxt_counter <= nxt_counter + 1;
    end

    ////////////////////////////////////////////////////////////////
    // Infer 2-bit counter to select which output to map to LEDs //
    //////////////////////////////////////////////////////////////
    // bumps once per SEL release: lft -> rght -> steer -> batt -> lft
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) out_sel_counter <= 0;
        else if (en_2bit) out_sel_counter <= out_sel_counter + 1;
    end

    //////////////////////////////////////////////////////
    // Infer Mux to select which output to map to LEDs //
    ////////////////////////////////////////////////////
    always_comb begin
        // only 8 LEDs, so show the top 8 bits
        case (out_sel_counter)
            2'b00: LED[7:0] = lft_ld[11:4];
            2'b01: LED[7:0] = rght_ld[11:4];
            2'b10: LED[7:0] = steer_pot[11:4];
            2'b11: LED[7:0] = batt[11:4];
            default: LED[7:0] = 0;
        endcase
    end

    //////////////////////
    // Instantiate DUT //
    ////////////////////
    A2D_intf iDUT (
        .clk(clk),
        .rst_n(rst_n),
        .nxt(nxt),
        .lft_ld(lft_ld),
        .rght_ld(rght_ld),
        .steer_pot(steer_pot),
        .batt(batt),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO)
    );

    ///////////////////////////////////////////////
    // Instantiate Push Button release detector //
    /////////////////////////////////////////////
    PB_release iPB (
        .clk(clk),
        .rst_n(rst_n),
        .PB(SEL),
        .released(en_2bit)
    );

    /////////////////////////////////////
    // Instantiate reset synchronizer //
    ///////////////////////////////////
    // RST_n comes straight off a PB, so synch it before anything uses it
    rst_synch iRST (
        .clk  (clk),
        .RST_n(RST_n),
        .rst_n(rst_n)
    );

endmodule
