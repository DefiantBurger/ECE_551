module sr_ff(
    input clk, async_reset_n, sync_set, sync_reset,
    output logic q
);
    always_ff @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n)
            q <= 1'b0;
        else if (sync_reset)
            q <= 1'b0;
        else if (sync_set)
            q <= 1'b1;
    end
endmodule

module PWM11(
    input logic         clk, rst_n,
    input logic [10:0]  duty,
    output logic        PWM1, PWM2, PWM_synch, ovr_I_blank
);
    localparam [10:0] NONOVERLAP = 11'h040;

    logic [10:0] cnt;

    d_ff i_dff_0[10:0](
        .d(cnt + 1'b1),
        .clk(clk),
        .rst_n(rst_n),
        .q(cnt)
    );

    assign PWM_synch = ~|cnt;
    assign ovr_I_blank = (NONOVERLAP < cnt && cnt < (NONOVERLAP + 128)) || 
                         ((NONOVERLAP + duty) < cnt && cnt < (NONOVERLAP + duty + 128));

    sr_ff i_sr_ff_pwm1(
        .clk(clk), .async_reset_n(rst_n), 
        .sync_set(cnt >= NONOVERLAP), 
        .sync_reset(cnt >= duty),
        .q(PWM1)
    );

    sr_ff i_sr_ff_pwm2(
        .clk(clk), .async_reset_n(rst_n), 
        .sync_set(cnt >= (duty + NONOVERLAP)), 
        .sync_reset(&cnt),
        .q(PWM2)
    );
endmodule
