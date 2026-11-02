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