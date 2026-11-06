module d_ff (
    input d,
    clk,
    rst_n,
    output logic q
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) q <= 0;
        else q <= d;
    end
endmodule
