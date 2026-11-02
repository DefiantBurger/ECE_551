module PID_Math(
    input logic signed [15:0] ptch, ptch_rt,
    input logic signed [17:0] integrator,
    output logic signed [11:0] PID_cntrl
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

    logic signed [14:0]  I_term;
    logic signed [15:0]  I_term_ext;

    assign I_term = integrator >>> 6;
    assign I_term_ext = {I_term[14], I_term};

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

endmodule