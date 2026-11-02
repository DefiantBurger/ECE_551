module PID_Math_tb();

    localparam PTCH_LOW = 16'hFF00;
    localparam PTCH_HIGH = 16'h00FF;
    localparam INTEGRATOR_LOW = 18'h3C000;
    localparam INTEGRATOR_LOW = 18'h03FFF;
    localparam PTCH_RT_LOW = 16'h0FFF;
    localparam PTCH_RT_HIGH = 16'hF000;

    logic [15:0] ptch;
    logic [17:0] integrator;
    logic [15:0] pitch_rt;
    logic [11:0] PID_cntrl;

    PID_MATH iDUT(
        .pitch(ptch),
        .integrator(integrator);
        .pitch_rt(pitch_rt),
        .PID_cntrl(PID_cntrl);
    )

    initial begin
        ptch = 0;
        integrator = 0;
        ptch_rt = 0;

        #10;

        for (int i = $signed(PTCH_LOW); i <= $signed(PTCH_HIGH); i++) begin
            ptch = i[15:0];
            #5;
        end
        
        $stop();
    end

endmodule