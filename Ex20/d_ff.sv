module d_ff (
    input d,
    clk,
    rst_n,
    output logic q
);
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) q <= 0;
        else q <= d;
    end
endmodule
