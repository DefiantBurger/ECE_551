module PWM11_tb();
    logic           clk, rst_n;
    logic [10:0]    duty;
    logic           PWM1, PWM2, PWM_synch, ovr_I_blank;

    PWM11 i_DUT(
        .clk(clk), .rst_n(rst_n), .duty(duty), 
        .PWM1(PWM1), .PWM2(PWM2), .PWM_synch(PWM_synch), 
        .ovr_I_blank(ovr_I_blank)
    );

    always #5 clk = ~clk; // 10 tick period

    initial begin
        clk = 0;
        rst_n = 0;
        #20
        rst_n = 1;
        #20
        duty = 11'h020; // 32 < 64 (0% duty cycle)
        #(10 * 2048 * 4) // clock period * timer length * runs thru timer
        duty = 11'h200; // 512 (~25% duty cycle)
        #(10 * 2048 * 4)
        duty = 11'h400; // 1024 (~50% duty cycle)
        #(10 * 2048 * 4)
        duty = 11'h600; // 1536 (~75% duty cycle)
        #(10 * 2048 * 4)
        duty = 11'h7FF; // 2047 (~100% duty cycle)
        #(10 * 2048 * 4)
        $stop();
    end
endmodule