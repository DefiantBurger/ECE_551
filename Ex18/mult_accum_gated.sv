module mult_accum_gated (
    clk,
    clr,
    en,
    A,
    B,
    accum
);

    input clk, clr, en;
    input [15:0] A, B;
    output reg [63:0] accum;

    reg [31:0] prod_reg;
    reg en_stg2;

    logic clk_en_lat_1, clk_en_lat_2;
    logic gclk1, gclk2;

    always_latch if (!clk) clk_en_lat_1 <= en;

    assign gclk1 = clk & clk_en_lat_1;

    ///////////////////////////////////////////
    // Generate and flop product if enabled //
    /////////////////////////////////////////
    always_ff @(posedge gclk1) prod_reg <= A * B;

    /////////////////////////////////////////////////////
    // Pipeline the enable signal to accumulate stage //
    ///////////////////////////////////////////////////
    always_ff @(posedge clk) en_stg2 <= en;

    always_latch if (!clk) clk_en_lat_2 <= en_stg2 || clr;

    assign gclk2 = clk & clk_en_lat_2;

    always_ff @(posedge gclk2)
        if (clr) accum <= 0;
        else accum <= accum + prod_reg;

endmodule
