// Random-vector check of balance_cntrl: applies 1500 stimulus vectors and
// compares outputs against the expected responses.
// Works against both the RTL (balance_cntrl.sv) and the synthesized gate-level
// netlist (balance_cntrl.vg), so it uses no parameter overrides or hierarchical refs.
`timescale 1ns / 1ps  // SAED32 cell models carry a timescale, so the TB needs one too
module balance_cntrl_chk_tb ();

    logic clk, rst_n, vld, pwr_up, rider_off, en_steer, too_fast;
    logic [15:0] ptch, ptch_rt;
    logic [11:0] steer_pot, lft_spd, rght_spd;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
    end

    // No #(.FAST_SIM()) override: the synthesized netlist has no parameters.
    // FAST_SIM is fixed at synthesis time by the elaborate line in balance_cntrl.dc.
    balance_cntrl i_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .pwr_up(pwr_up),
        .rider_off(rider_off),
        .en_steer(en_steer),
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .steer_pot(steer_pot),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .too_fast(too_fast)
    );

    // Stimulus and expected-response memories, loaded from .hex files
    reg   [48:0] stim_mem [1500];
    reg   [24:0] resp_mem [1500];

    // Unpack the current stimulus vector onto the DUT inputs
    logic [48:0] stim_vec;
    assign rst_n     = stim_vec[48];
    assign vld       = stim_vec[47];
    assign ptch      = stim_vec[46:31];
    assign ptch_rt   = stim_vec[30:15];
    assign pwr_up    = stim_vec[14];
    assign rider_off = stim_vec[13];
    assign steer_pot = stim_vec[12:1];
    assign en_steer  = stim_vec[0];

    logic [24:0] resp_vec;
    int errors = 0;  // number of mismatched output signals

    initial begin
        $readmemh("balance_cntrl_stim.hex", stim_mem);
        $readmemh("balance_cntrl_resp.hex", resp_mem);

        // HW5 vectors were generated with ss_tmr free-running, so no force here.
        // (A hierarchical force wouldn't survive synthesis/flattening anyway.)
        // force i_DUT.ss_tmr = '1;

        for (int i = 0; i < 1500; i++) begin
            // Apply the vector on a negedge (or at t=0), away from the active posedge
            stim_vec = stim_mem[i];
            resp_vec = resp_mem[i];

            // Let the DUT clock in the vector, then give the gates half a cycle to
            // settle before checking. Inputs still hold vector i at this point.
            @(posedge clk);
            @(negedge clk);

            assert (lft_spd === resp_vec[24:13])
            else begin
                $error("vec %0d: lft_spd=%h exp=%h", i, lft_spd, resp_vec[24:13]);
                errors++;
            end
            assert (rght_spd === resp_vec[12:1])
            else begin
                $error("vec %0d: rght_spd=%h exp=%h", i, rght_spd, resp_vec[12:1]);
                errors++;
            end
            assert (too_fast === resp_vec[0])
            else begin
                $error("vec %0d: too_fast=%h exp=%h", i, too_fast, resp_vec[0]);
                errors++;
            end
        end

        if (errors == 0) $display("PASS: all test vectors matched.");
        else $display("FAIL: %0d mismatches.", errors);

        $stop;
    end


endmodule
