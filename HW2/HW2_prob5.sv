// 1. The code isn't correct because a latch should change with d when clk is high, 
// that code doesn't implement that correctly. It only changes once when clk changes.
// This behavior represents a flip flop, not a latch.

// 2.
module d_ff_sync_reset(
    input d, clk, sync_reset,
    output logic q
);
    always_ff @(posedge clk) begin
        if (sync_reset)
            q <= 1'b0;
        else
            q <= d;
    end
endmodule

// 3.
module d_ff_async_reset_en(
    input d, clk, async_reset_n, en,
    output logic q
);
    always_ff @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n)
            q <= 1'b0;
        else if (en)
            q <= d;
    end
endmodule

// 4.
module sr_ff(
    input clk, async_reset_n, sync_set, sync_reset,
    output logic q
);
    always_ff @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n || sync_reset)
            q <= 1'b0;
        else if (sync_set)
            q <= 1'b1;
    end
endmodule

// 5. always_ff doesn't ensure that the logic will infer a flop because there could
// be logic errors in how the flop is set up: e.g. incorrect sensitivity list.

