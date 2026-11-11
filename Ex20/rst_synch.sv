module rst_synch (
    input  clk,
    RST_n,
    output rst_n
);
    logic rst_meta;

    d_ff i_dff_0 (
        .d(1),
        .clk(clk),
        .rst_n(RST_n),
        .q(rst_meta)
    );
    d_ff i_dff_1 (
        .d(rst_meta),
        .clk(clk),
        .rst_n(RST_n),
        .q(rst_n)
    );
endmodule
