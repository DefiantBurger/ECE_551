`default_nettype none

module inertial_integrator (
    input  wire clk,
    input  wire rst_n,
    input  wire vld,
    input  wire signed [15:0] ptch_rt,
    input  wire signed [15:0] AZ,
    output wire signed [15:0] ptch
);

  localparam signed [15:0] PTCH_RT_OFFSET = 16'h0050;
  localparam signed [15:0] AZ_OFFSET = 16'h0010;

  ////////////////////////////////////////////////////////////////
  // 1. Compensated Sensor Calculations
  ////////////////////////////////////////////////////////////////
  wire signed [15:0] ptch_rt_comp;
  wire signed [15:0] AZ_comp;

  assign ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;
  assign AZ_comp = AZ - AZ_OFFSET;

  ////////////////////////////////////////////////////////////////
  // 2. Accelerometer Pitch Angle Estimate
  ////////////////////////////////////////////////////////////////
  wire signed [25:0] ptch_acc_product;
  wire signed [15:0] ptch_acc;

  assign ptch_acc_product = AZ_comp * $signed(16'd327);
  assign ptch_acc = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]};

  ////////////////////////////////////////////////////////////////
  // 3. Sensor Fusion Offset Term
  ////////////////////////////////////////////////////////////////
  wire signed [11:0] fusion_ptch_offset;

  assign fusion_ptch_offset = (ptch_acc > ptch) ? $signed(12'sd1024) : $signed(-12'sd1024);

  ////////////////////////////////////////////////////////////////
  // 4. Integrating Accumulator
  ////////////////////////////////////////////////////////////////
  reg signed [26:0] ptch_int;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      ptch_int <= 27'sd0;
    else if (vld)
      ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}}, ptch_rt_comp} + {{15{fusion_ptch_offset[11]}}, fusion_ptch_offset};
  end

  // Upper bits [26:11] form the scaled 16-bit pitch output
  assign ptch = ptch_int[26:11];

endmodule

`default_nettype wire