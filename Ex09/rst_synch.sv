module rst_synch(
    input clk, RST_n,
    output rst_n
);
    logic q;

    d_ff i_dff_0(.d(1'b1), .clk(clk), .rst_n(RST_n), .q(q));
    d_ff i_dff_1(.d(q), .clk(clk), .rst_n(RST_n), .q(rst_n));
endmodule