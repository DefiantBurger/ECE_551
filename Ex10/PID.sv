module PID(
    input clk, rst_n, vld, pwr_up, rider_off,
    input signed [15:0] ptch, ptch_rt,
    output signed [11:0] PID_cntrl,
    output [7:0] ss_tmr
);
    logic signed [9:0]   pitch_err_sat;
    localparam signed [4:0] P_COEFF = 5'sh09;
    logic signed [14:0]  P_term;
    logic signed [15:0]  P_term_ext;

    saturate #(.IN_WIDTH(16), .OUT_WIDTH(10), .IS_SIGNED(1)) i_sat_pitch(
        .in_val(ptch),
        .out_val(pitch_err_sat)
    );

    assign P_term = pitch_err_sat * P_COEFF;
    assign P_term_ext = {P_term[14], P_term};

    // ---

    logic signed [17:0] I_term;
    logic signed [17:0] pitch_err_sat_ext;
    logic signed [17:0] accum_sum;

    assign pitch_err_sat_ext = {{8{pitch_err_sat[9]}}, pitch_err_sat};
    assign accum_sum = I_term + pitch_err_sat;

    logic ov;
    assign ov = (!(I_term[17] ^ pitch_err_sat_ext[17])) && (I_term[17] ^ accum_sum[17]);

    logic signed [17:0] next_accum;
    assign next_accum = 
        rider_off ? 18'h00000 : 
        (vld && !ov) ? accum_sum : 
        I_term;
    
    always_ff @( posedge clk or negedge rst_n ) begin
        if (!rst_n)
            I_term <= 18'h00000;
        else if (clk)
            I_term <= next_accum;
        else
            I_term <= I_term;
    end
    
    logic signed [15:0] I_term_ext;
    assign I_term_ext = {{4{I_term[17]}}, I_term[17:6]};

    // ---

    logic signed [12:0]  ptch_rt_div_64, D_term;
    logic signed [15:0]  D_term_ext;
    
    assign ptch_rt_div_64 = ptch_rt >>> 6;
    assign D_term = -ptch_rt_div_64;
    assign D_term_ext = {{3{D_term[12]}}, D_term[12:0]};

    // ---

    logic signed [15:0]  sum;

    assign sum = P_term_ext + I_term_ext + D_term_ext;

    saturate #(.IN_WIDTH(16), .OUT_WIDTH(12), .IS_SIGNED(1)) i_sat_pid(
        .in_val(sum),
        .out_val(PID_cntrl)
    );

    // ---

    logic [26:0] long_tmr;
    logic [26:0] nxt_tmr;
    logic near_full;

    assign near_full = &long_tmr[26:19];
    assign nxt_tmr = pwr_up ? long_tmr + !near_full : 27'h0000000;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            long_tmr <= 18'h00000;
        else if (clk)
            long_tmr <= nxt_tmr;
        else
            long_tmr <= long_tmr;
    end

    assign ss_tmr = long_tmr[26:19];

endmodule