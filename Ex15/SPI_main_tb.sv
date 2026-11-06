module SPI_main_tb ();

    logic clk, rst_n;

    always #10 clk <= ~clk;

    initial clk = 0;

    logic SS_n, SCLK, MOSI, MISO, INT;
    SPI_iNEMO1 i_receiver (
        // Inputs
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),

        // Outputs
        .MISO(MISO),
        .INT (INT)
    );

    logic wrt, done;
    logic [15:0] wt_data, rd_data;
    SPI_main i_DUT (
        // Inputs
        .clk(clk),
        .rst_n(rst_n),
        .MISO(MISO),
        .wrt(wrt),
        .wt_data(wt_data),

        // Outputs
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .done(done),
        .rd_data(rd_data)
    );

    task automatic send(input logic [15:0] cmd, input logic [7:0] expected, input logic skip_check);
        fork : send_fork
            begin
                @(negedge clk) wt_data = cmd;
                @(negedge clk) wrt = 1;
                @(negedge clk) wrt = 0;

                @(posedge done);

                if (!skip_check && rd_data[7:0] !== expected) begin
                    $display("Test failed! Incorrect data %h doesn't match %h.", rd_data[7:0],
                             expected);
                    $stop;
                end
            end

            begin
                repeat (1000) @(posedge clk);
                $display("Test failed! Timeout with data %h.", cmd);
                $stop;
            end
        join_any

        disable send_fork;
    endtask

    initial begin
        rst_n = 0;
        wrt   = 0;

        @(negedge clk) rst_n = 1;

        repeat (3) @(posedge clk);

        // Read WHO_AM_I (test a few different lower 8 bits as they are don't cares)
        send(16'h8F00, 8'h6A, 0);
        send(16'h8F01, 8'h6A, 0);
        send(16'h8F8E, 8'h6A, 0);
        send(16'h8FFF, 8'h6A, 0);

        // Configure INT (write 0x02 to 0x0D), response doesn't matter
        send(16'h0D02, 8'h00, 1);
        @(posedge clk);
        if (!i_receiver.NEMO_setup) begin
            $display("Test failed! NEMO_setup not asserted after INT config write.");
            $stop;
        end

        // Wait for first set of data (row 0 of inert_data.hex)
        fork : wait_int_0
            @(posedge INT);
            begin
                repeat (50000) @(posedge clk);
                $display("Test failed! Timeout waiting for INT.");
                $stop;
            end
        join_any
        disable wait_int_0;

        // Reading ptchL should clear INT
        send(16'hA200, 8'h63, 0);  // ptchL
        repeat (10) @(posedge clk);
        if (INT) begin
            $display("Test failed! INT not cleared after reading ptchL.");
            $stop;
        end

        // Rest of row 0: 3524_5e81_d609_5663_7b0d_998d
        send(16'hA300, 8'h56, 0);  // ptchH
        send(16'hA400, 8'h0D, 0);  // rollL
        send(16'hA500, 8'h7B, 0);  // rollH
        send(16'hA600, 8'h8D, 0);  // yawL
        send(16'hA700, 8'h99, 0);  // yawH
        send(16'hA800, 8'h24, 0);  // AXL
        send(16'hA900, 8'h35, 0);  // AXH

        // Wait for next set of data (row 1: 8465_5212_e301_cd0d_f176_cd3d)
        fork : wait_int_1
            @(posedge INT);
            begin
                repeat (50000) @(posedge clk);
                $display("Test failed! Timeout waiting for second INT.");
                $stop;
            end
        join_any
        disable wait_int_1;

        send(16'hA200, 8'h0D, 0);  // ptchL
        send(16'hA300, 8'hCD, 0);  // ptchH
        send(16'hA600, 8'h3D, 0);  // yawL
        send(16'hA700, 8'hCD, 0);  // yawH

        $display("All tests passed!");
        $stop;
    end

endmodule
