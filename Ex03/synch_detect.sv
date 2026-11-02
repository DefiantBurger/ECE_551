module synch_detect(
    input clk,
    input rst_n,
    input asynch_sig_in,
    output rise_edge
);
    wire q1, q2, q3, not_q3;

    dff iDFF1 (
        .D(asynch_sig_in),
        .clk(clk),
        .PRN(rst_n),
        .Q(q1)
    );

    dff iDFF2 (
        .D(q1),
        .clk(clk),
        .PRN(rst_n),
        .Q(q2)
    );

    dff iDFF3 (
        .D(q2),
        .clk(clk),
        .PRN(rst_n),
        .Q(q3)
    );

    not NOT1(not_q3, q3);
    and AND1(rise_edge, q2, not_q3);

endmodule