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

    logic clk_en_lat_1;
    always_latch begin
        if (!clk) clk_en_lat_1 <= en;
    end

    ///////////////////////////////////////////
    // Generate and flop product if enabled //
    /////////////////////////////////////////
    always_ff @(posedge clk) if (clk_en_lat_1) prod_reg <= A * B;

    /////////////////////////////////////////////////////
    // Pipeline the enable signal to accumulate stage //
    ///////////////////////////////////////////////////
    always_ff @(posedge clk) en_stg2 <= en;

    logic clk_en_lat_2;
    always_latch begin
        if (!clk) clk_en_lat_2 <= en_stg2 || clr;
    end

    always_ff @(posedge clk)
        if (clr) accum <= 64'h0000000000000000;
        else if (clk_en_lat_2) accum <= accum + prod_reg;

endmodule
