module PB_release(
    input PB, clk, rst_n,
    output released
);
    logic q0, q1, q2;

    d_ff i_dff_0(.d(PB), .clk(clk), .rst_n(rst_n), .q(q0));
    d_ff i_dff_1(.d(q0), .clk(clk), .rst_n(rst_n), .q(q1));
    d_ff i_dff_2(.d(q1), .clk(clk), .rst_n(rst_n), .q(q2));

    assign released = q1 && !q2;
endmodule