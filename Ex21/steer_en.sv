module steer_en #(
    parameter bit FAST_SIM = 1
) (
    input rst_n,
    clk,
    input [11:0] lft_ld,
    rght_ld,
    output en_steer,
    rider_off
);
    localparam logic [12:0] MIN_RIDER_WT = 13'h200;
    localparam logic [12:0] WT_HYSTERESIS = 13'h040;

    // Hysteresis band around MIN_RIDER_WT so sum_gt/lt_min don't oscillate near the threshold
    localparam logic [12:0] RIDER_HYST_LOW = MIN_RIDER_WT - WT_HYSTERESIS;
    localparam logic [12:0] RIDER_HYST_HIGH = MIN_RIDER_WT + WT_HYSTERESIS;


    logic sum_lt_min, sum_gt_min, diff_gt_1_4, diff_gt_15_16;
    logic [12:0] ld_sum, sum_scale_15_16, sum_scale_1_4, abs_ld_diff;

    assign sum_lt_min = ld_sum < RIDER_HYST_LOW;
    assign sum_gt_min = ld_sum > RIDER_HYST_HIGH;

    assign ld_sum = lft_ld + rght_ld;  // 13 bits so the sum can't overflow
    assign sum_scale_1_4 = ld_sum >> 2;
    assign sum_scale_15_16 = ld_sum - (ld_sum >> 4);  // x - x/16 = 15/16*x, no multiplier

    logic signed [11:0] ld_diff;

    assign ld_diff = lft_ld - rght_ld;
    assign abs_ld_diff = (ld_diff < 0) ? -ld_diff : ld_diff;
    assign diff_gt_1_4 = abs_ld_diff > sum_scale_1_4;
    assign diff_gt_15_16 = abs_ld_diff > sum_scale_15_16;

    logic clr_tmr, tmr_full;

    steer_en_SM i_steer_en_SM (
        .clk(clk),  // 50MHz clock
        .rst_n(rst_n),
        .tmr_full(tmr_full),
        .sum_gt_min(sum_gt_min),
        .sum_lt_min(sum_lt_min),
        .diff_gt_1_4(diff_gt_1_4),
        .diff_gt_15_16(diff_gt_15_16),
        .clr_tmr(clr_tmr),
        .en_steer(en_steer),
        .rider_off(rider_off)
    );

    // 2^26 clocks / 50MHz = ~1.34s
    logic [25:0] tmr_count;

    // FAST_SIM only checks the low 15 bits so sims don't take 67M cycles
    generate
        if (FAST_SIM) assign tmr_full = &tmr_count[14:0];
        else assign tmr_full = &tmr_count;
    endgenerate

    // clr_tmr is asserted by SM on rst_n
    always_ff @(posedge clk) begin
        if (clr_tmr) tmr_count <= '0;
        else tmr_count <= tmr_count + 1;
    end

endmodule
