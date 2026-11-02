module saturate(
    input   [15:0]  unsigned_err,
    output  [9:0]   unsigned_err_sat,
    input   [15:0]  signed_err,
    output  [9:0]   signed_err_sat,
    input   [9:0]   signed_D_diff,
    output  [6:0]   signed_D_diff_sat
);
    assign unsigned_err_sat = (|unsigned_err[15:10]) ? 10'hFFF : unsigned_err[9:0];

    assign signed_err_sat = 
        (signed_err[15]) ? 
            (
                (!(&signed_err[14:9])) ? 10'hE00 : signed_err[9:0]
            ) : 
            (
                (|signed_err[14:9]) ? 10'h1FF : signed_err[9:0]
            );

    assign signed_D_diff_sat = 
        (signed_D_diff[9]) ? 
            (
                (!(&signed_D_diff[8:6])) ? 7'hC0 : signed_D_diff[6:0]
            ) : 
            (
                (|signed_D_diff[8:6]) ? 7'h3F : signed_D_diff[6:0]
            );

endmodule
