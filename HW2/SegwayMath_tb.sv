module SegwayMath_tb();
    logic signed [11:0] PID_cntrl;
    logic [7:0] ss_tmr;
    logic [11:0] steer_pot;
    logic en_steer, pwr_up;
    logic signed [11:0] lft_spd, rght_spd;
    logic too_fast;

    SegwayMath iDUT(
        .PID_cntrl(PID_cntrl),
        .ss_tmr(ss_tmr),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .pwr_up(pwr_up),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .too_fast(too_fast)
    );

    initial begin
        en_steer = 0;
        pwr_up = 1;
        PID_cntrl = 12'h5FF;
        ss_tmr = 0;
        steer_pot = 0;

        for (int i = 0; i <= 8'hFF; i++) begin
            #5 ss_tmr = i;
        end

        #100;

        for (int i = 12'sh5FF; i >= 12'shE00; i--) begin
            #5 PID_cntrl = i;
        end

        #1000;

        en_steer = 1;

        for (int i = 12'sh3FF; i >= 12'shC00; i--) begin
            PID_cntrl = i;
            #5 steer_pot = -2 * i + 2046;
        end

        #100;

        pwr_up = 0;

        #1000;

        $stop();
    end
endmodule