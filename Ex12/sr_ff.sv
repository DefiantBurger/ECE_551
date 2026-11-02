module sr_ff(
    input clk, rst_n, set, reset,
    output logic q
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= '0;
        else if (reset)
            q <= '0;
        else if (set)
            q <= '1;
    end
endmodule