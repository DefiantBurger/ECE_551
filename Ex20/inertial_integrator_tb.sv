`default_nettype none

module inertial_integrator_tb();

  logic clk, rst_n;
  logic vld;
  logic signed [15:0] ptch_rt;
  logic signed [15:0] AZ;
  wire  signed [15:0] ptch;

  localparam signed [15:0] PTCH_RT_OFFSET = 16'h0050;

  inertial_integrator iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .vld(vld),
    .ptch_rt(ptch_rt),
    .AZ(AZ),
    .ptch(ptch)
  );

  always #10 clk = ~clk;

  initial begin
    clk     = 0;
    rst_n   = 0;
    vld     = 1; // Held high (as directed by the exercise slides)
    ptch_rt = 16'h0000;
    AZ      = 16'h0000;

    // Reset sequence
    repeat (5) @(negedge clk);
    rst_n = 1;
    @(negedge clk);

    $display("=== Starting inertial_integrator Simulation ===");

    // Step 1: Apply ptch_rt = (16'h1000 + OFFSET), AZ = 0 for 500 clocks
    // Pitch should trend strongly negative
    ptch_rt = 16'h1000 + PTCH_RT_OFFSET;
    AZ = 16'h0000;
    repeat (500) @(posedge clk);
    $display("After 500 clocks negative slope: ptch = %d", ptch);

    // Step 2: Zero pitch rate (ptch_rt = OFFSET), hold for 1000 clocks
    // Due to AZ=0 fusion, pitch trends slowly back toward 0
    ptch_rt = PTCH_RT_OFFSET;
    repeat (1000) @(posedge clk);
    $display("After 1000 clocks recovery toward zero: ptch = %d", ptch);

    // Step 3: Set ptch_rt = (OFFSET - 16'h1000) for 500 clocks
    // Pitch should trend steeply into positive values
    ptch_rt = PTCH_RT_OFFSET - 16'h1000;
    repeat (500) @(posedge clk);
    $display("After 500 clocks positive slope: ptch = %d", ptch);

    // Step 4: Zero pitch rate again for 1000 clocks
    // Pitch trends slowly back down toward zero
    ptch_rt = PTCH_RT_OFFSET;
    repeat (1000) @(posedge clk);
    $display("After 1000 clocks recovery toward zero: ptch = %d", ptch);

    // Step 5: Adjust AZ = 16'h0800
    // When ptch reaches ~100, it levels off as fusion_ptch_offset alternates
    AZ = 16'h0800;
    repeat (2000) @(posedge clk);
    $display("After leveling off at AZ=0x0800 target: ptch = %d", ptch);

    $display("=== Simulation Complete. Inspect waveforms to verify curve. ===");
    $stop();
  end

endmodule

`default_nettype wire
  