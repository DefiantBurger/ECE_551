module up_dwn_cnt4(
    input en, dwn, clk, rst_n,
    output [3:0] cnt
);
    logic [3:0] add_sub_out;
    logic [3:0] next_cnt;

    assign add_sub_out = dwn ? (cnt - 4'd1) : (cnt + 4'd1);
    assign next_cnt = en ? add_sub_out : cnt;

    d_ff i_dff[3:0](
        .d(next_cnt),
        .clk(clk),
        .rst_n(rst_n),
        .q(cnt)
    );
endmodule