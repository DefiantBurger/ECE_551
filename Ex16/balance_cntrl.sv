// Balance controller: PID computes the control signal from pitch, and
// SegwayMath turns it (scaled by the soft-start timer) into motor speeds.
module balance_cntrl #(
    parameter bit FAST_SIM = 1
) (
    input clk,
    rst_n,
    vld,
    pwr_up,
    rider_off,
    en_steer,
    input [15:0] ptch,
    ptch_rt,
    input [11:0] steer_pot,
    output [11:0] lft_spd,
    rght_spd,
    output too_fast
);
    // Signals connecting PID to SegwayMath
    logic [11:0] PID_cntrl;
    logic [ 7:0] ss_tmr;

    // FAST_SIM is passed down to speed up the integrator and ss_tmr in simulation

    PID #(
        .FAST_SIM(FAST_SIM)
    ) i_PID (
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .pwr_up(pwr_up),
        .rider_off(rider_off),
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .PID_cntrl(PID_cntrl),
        .ss_tmr(ss_tmr)
    );

    SegwayMath i_SegwayMath (
        .PID_cntrl(PID_cntrl),
        .ss_tmr(ss_tmr),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .pwr_up(pwr_up),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .too_fast(too_fast)
    );


endmodule
