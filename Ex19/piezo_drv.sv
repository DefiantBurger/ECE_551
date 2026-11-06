module piezo_drv_SM (
    input clk,
    rst_n,
    en_steer,
    too_fast,
    batt_low,
    dur_done,  // current note has played for its full duration
    rpt_done,  // 3s repeat timer has expired
    output logic clr_dur,  // clear duration/frequency timers (note change)
    output logic clr_rpt,  // clear repeat timer (tune starting)
    output logic [17:0] mid_freq_count,
    output logic [17:0] max_freq_count,
    output logic [24:0] dur_count
);

    // Charge Fanfare: G6 (1568), C7 (2093), E7 (2637), G7 (3136), E7, G7
    typedef enum logic [2:0] {
        OFF,
        G6_1,
        C7_2,
        E7_3,
        G7_4,
        E7_5,
        G7_6
    } note_t;
    note_t current_note, next_note;

    // direction of tune, latched when tune starts (1 = backwards for batt_low)
    logic backward, ld_dir, dir_in;

    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) current_note <= OFF;
        else current_note <= next_note;
    end

    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) backward <= 0;
        else if (ld_dir) backward <= dir_in;
    end

    // next state logic
    always_comb begin
        next_note = current_note;
        clr_dur   = 0;
        clr_rpt   = 0;
        ld_dir    = 0;
        dir_in    = 0;

        case (current_note)
            OFF: begin
                if (too_fast) begin
                    next_note = G6_1;
                    clr_dur = 1;
                    ld_dir = 1;  // dir_in = 0 -> forward
                end else if ((en_steer || batt_low) && rpt_done) begin
                    next_note = batt_low ? G7_6 : G6_1;
                    clr_dur = 1;
                    clr_rpt = 1;
                    ld_dir = 1;
                    dir_in = batt_low;
                end
            end
            G6_1:
            if (dur_done) begin
                next_note = (too_fast || !backward) ? C7_2 : OFF;
                clr_dur   = 1;
            end
            C7_2:
            if (dur_done) begin
                next_note = (too_fast || !backward) ? E7_3 : G6_1;
                clr_dur   = 1;
            end
            E7_3:
            if (dur_done) begin
                if (too_fast) next_note = G6_1;
                else if (backward) next_note = C7_2;
                else next_note = G7_4;
                clr_dur = 1;
            end
            // too_fast has priority, so it preempts the last 3 notes
            G7_4:
            if (too_fast) begin
                next_note = G6_1;
                clr_dur = 1;
                ld_dir = 1;
            end else if (dur_done) begin
                next_note = backward ? E7_3 : E7_5;
                clr_dur   = 1;
            end
            E7_5:
            if (too_fast) begin
                next_note = G6_1;
                clr_dur = 1;
                ld_dir = 1;
            end else if (dur_done) begin
                next_note = backward ? G7_4 : G7_6;
                clr_dur   = 1;
            end
            G7_6:
            if (too_fast) begin
                next_note = G6_1;
                clr_dur = 1;
                ld_dir = 1;
            end else if (dur_done) begin
                next_note = backward ? E7_5 : OFF;
                clr_dur   = 1;
            end
            default: next_note = OFF;
        endcase
    end

    always_comb begin
        case (current_note)
            OFF: begin
                mid_freq_count = 0;
                max_freq_count = 0;
                dur_count = 0;
            end
            G6_1: begin
                mid_freq_count = 15944;  // 50% duty cycle
                max_freq_count = 31888;
                dur_count = 25'd1 << 23;
            end
            C7_2: begin
                mid_freq_count = 11945;
                max_freq_count = 23889;
                dur_count = 25'd1 << 23;
            end
            E7_3: begin
                mid_freq_count = 9480;
                max_freq_count = 18961;
                dur_count = 25'd1 << 23;
            end
            G7_4: begin
                mid_freq_count = 7972;
                max_freq_count = 15944;
                dur_count = (25'd1 << 23) + (25'd1 << 22);
            end
            E7_5: begin
                mid_freq_count = 9480;
                max_freq_count = 18961;
                dur_count = 25'd1 << 22;
            end
            G7_6: begin
                mid_freq_count = 7972;
                max_freq_count = 15944;
                dur_count = 25'd1 << 24;
            end
            default: begin
                mid_freq_count = 0;
                max_freq_count = 0;
                dur_count = 0;
            end
        endcase
    end

endmodule

module piezo_drv #(
    bit FAST_SIM = 1,
    int SIM_INCR = 64   // speedup when FAST_SIM (spec is 64, raise in TB for quicker sims)
) (
    input  clk,   // 50 MHz clock
    rst_n,
    en_steer,
    too_fast,
    batt_low,
    output piezo,
    piezo_n
);

    localparam logic [11:0] INCR = FAST_SIM ? 12'(SIM_INCR) : 12'd1;

    /*
    freq_timer is the timer used for generated a signal of a specific frequency
    mid_freq_count is the configurable midpoint to go from ON to OFF for a duty cycle
    max_freq_count is the max value of the timer to reset to 0 for a specific freq
    18 bits is the highest count necessary (300 Hz)
    */
    logic [17:0] freq_timer, mid_freq_count, max_freq_count;
    logic clr_dur, clr_rpt;  // driven by FSM
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) freq_timer <= 0;
        else if (clr_dur || freq_timer >= max_freq_count) freq_timer <= 0;
        else freq_timer <= freq_timer + INCR;
    end

    // note duration timer, cleared on each note change
    logic [24:0] dur_timer, dur_count;
    logic dur_done;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) dur_timer <= 0;
        else if (clr_dur) dur_timer <= 0;
        else if (!dur_done) dur_timer <= dur_timer + INCR;
    end
    assign dur_done = dur_timer >= dur_count;

    // 3 second repeat timer (3s * 50MHz = 150M clocks -> 28 bits), saturates
    // resets to RPT_COUNT so the first tune plays immediately
    localparam logic [27:0] RPT_COUNT = 28'd150_000_000;
    logic [27:0] rpt_timer;
    logic rpt_done;
    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n) rpt_timer <= RPT_COUNT;
        else if (clr_rpt) rpt_timer <= 0;
        else if (!rpt_done) rpt_timer <= rpt_timer + INCR;
    end
    assign rpt_done = rpt_timer >= RPT_COUNT;

    // piezo is silent in OFF since mid_freq_count = 0
    assign piezo = (freq_timer < mid_freq_count);
    assign piezo_n = !piezo;

    piezo_drv_SM iSM (
        .clk(clk),
        .rst_n(rst_n),
        .en_steer(en_steer),
        .too_fast(too_fast),
        .batt_low(batt_low),
        .dur_done(dur_done),
        .rpt_done(rpt_done),
        .clr_dur(clr_dur),
        .clr_rpt(clr_rpt),
        .mid_freq_count(mid_freq_count),
        .max_freq_count(max_freq_count),
        .dur_count(dur_count)
    );

endmodule
