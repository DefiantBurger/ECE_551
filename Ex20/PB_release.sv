module PB_release(
    input PB, clk, rst_n,
    output released
);
    logic q0, q1, q2;

    // Preset to 1 (button idles high via pull-up) so reset doesn't look like a release
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) {q0, q1, q2} <= 3'b111;
        else {q0, q1, q2} <= {PB, q0, q1};
    end

    assign released = q1 && !q2;
endmodule
