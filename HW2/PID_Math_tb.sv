module PID_Math_tb();
    localparam signed [15:0] PTCH_0 = 16'hFF00; // -256
    localparam signed [15:0] PTCH_8 = 16'h00FF; // +255
    localparam signed [17:0] INTEGRATOR_LOW = 18'h3C000; // -16384
    localparam signed [17:0] INTEGRATOR_HIGH = 18'h03FFF; // +16383
    localparam signed [15:0] PTCH_RT_LOW = 16'h0FFF; // +4095
    localparam signed [15:0] PTCH_RT_HIGH = 16'hF000; // -4096

    logic signed [15:0] ptch;
    logic signed [17:0] integrator;
    logic signed [15:0] ptch_rt;
    logic signed [11:0] PID_cntrl;

    PID_Math i_DUT(
        .ptch(ptch),
        .integrator(integrator),
        .ptch_rt(ptch_rt),
        .PID_cntrl(PID_cntrl)
    );

    initial begin
        // Initial values
        ptch = PTCH_0;
        integrator = INTEGRATOR_LOW;
        ptch_rt = PTCH_RT_LOW;

        #10;

        fork
            // ptch starts at 16'hFF00 (-256), ramps to 16'h00FF (+255)
            begin : ramp_ptch
                for (int i = -256; i <= 255; i++) begin
                    ptch = 16'(signed'(i));
                    #5;
                end
            end

            // integrator ramps up/down four times: 18'h3C000 to 18'h03FFF
            begin : ramp_integrator
                repeat (2) begin
                    // Ramp up: 18'h3C000 to 18'h03FFF (128 steps)
                    for (int i = 0; i < 128; i++) begin
                        integrator = 18'(signed'(INTEGRATOR_LOW) + ((signed'(INTEGRATOR_HIGH) - signed'(INTEGRATOR_LOW)) * i) / 127);
                        #5;
                    end
                    // Ramp down: 18'h03FFF to 18'h3C000 (128 steps)
                    for (int i = 0; i < 128; i++) begin
                        integrator = 18'(signed'(INTEGRATOR_HIGH) - ((signed'(INTEGRATOR_HIGH) - signed'(INTEGRATOR_LOW)) * i) / 127);
                        #5;
                    end
                end
            end

            // ptch_rt ramps down/up eight times: 16'h0FFF to 16'hF000
            begin : ramp_ptch_rt
                repeat (4) begin
                    // Ramp down: 16'h0FFF to 16'hF000 (64 steps)
                    for (int i = 0; i < 64; i++) begin
                        ptch_rt = 16'(signed'(PTCH_RT_LOW) - ((signed'(PTCH_RT_LOW) - signed'(PTCH_RT_HIGH)) * i) / 63);
                        #5;
                    end
                    // Ramp up: 16'hF000 to 16'h0FFF (64 steps)
                    for (int i = 0; i < 64; i++) begin
                        ptch_rt = 16'(signed'(PTCH_RT_HIGH) + ((signed'(PTCH_RT_LOW) - signed'(PTCH_RT_HIGH)) * i) / 63);
                        #5;
                    end
                end
            end
        join

        #10;
        $stop();
    end
endmodule
