module saturate #(
    parameter int IN_WIDTH = 16,
    parameter int OUT_WIDTH = 10
)(
    input logic signed [IN_WIDTH-1:0] in_val,
    output logic signed [OUT_WIDTH-1:0] out_val
);

    localparam logic signed [OUT_WIDTH-1:0] MAX_VAL = (1 << (OUT_WIDTH - 1)) - 1;
    localparam logic signed [OUT_WIDTH-1:0] MIN_VAL = -(1 << (OUT_WIDTH - 1));

    assign out_val = 
        (in_val[IN_WIDTH-1]) ? 
            (
                (!(&in_val[IN_WIDTH-2:OUT_WIDTH-1])) ? MIN_VAL : in_val[OUT_WIDTH-1:0]
            ) : 
            (
                (|in_val[IN_WIDTH-2:OUT_WIDTH-1]) ? MAX_VAL : in_val[OUT_WIDTH-1:0]
            );

endmodule

module PID_Math(
    input logic signed [15:0] pitch, pitch_rt,
    input logic signed [17:0] integrator,
    output logic signed [11:0] PID_cntrl
);
    logic signed [9:0]   pitch_err_sat;
    localparam signed P_COEFF = 5'h09;
    logic signed [14:0]  P_term;
    logic signed [15:0]  P_term_ext;

    saturate #(.IN_WIDTH(16), .OUT_WIDTH(10)) i_sat_pitch(
        .in_val(pitch),
        .out_val(pitch_err_sat)
    );

    assign P_term = pitch_err_sat * P_COEFF;
    assign P_term_ext = {P_term[14],P_term[14:0]};

    // ---

    logic signed [14:0]  I_term;
    logic signed [15:0]  I_term_ext;

    assign I_term = integrator >>> 6;
    assign I_term_ext = {integrator[14],integrator[14:0]};

    // ---

    logic signed [12:0]  pitch_rt_div_64, D_term;
    logic signed [15:0]  D_term_ext;
    
    assign pitch_rt_div_64 = pitch_rt >>> 6;
    assign D_term = -pitch_rt_div_64;
    assign D_term_ext = {{3{D_term[12]}}, D_term[12:0]};

    // ---

    logic signed [15:0]  sum;

    assign sum = P_term_ext + I_term_ext + D_term_ext;

    saturate #(.IN_WIDTH(16), .OUT_WIDTH(12)) i_sat_pid(
        .in_val(sum),
        .out_val(PID_cntrl)
    );

endmodule;