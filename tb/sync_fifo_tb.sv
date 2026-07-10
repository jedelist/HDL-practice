`timescale 1ns/1ps

module sync_fifo_tb;

    localparam int DATA_WIDTH = 8;
    localparam int DEPTH = 8;
    localparam time CLK_PERIOD = 10ns;

    logic                   clk = 1'b0;
    logic                   rst = 1'b0;

    logic                   wr_en = 1'b0;
    logic                   rd_en = 1'b0;
    logic [DATA_WIDTH-1:0]  din   = '0;
    logic [DATA_WIDTH-1:0]  dout;

    logic                   full;
    logic                   empty;

    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    always #(CLK_PERIOD / 2) clk = ~clk;

    task automatic check_flags(
        input logic expected_full,
        input logic expected_empty,
        input string message
    );
        begin
            if (full !== expected_full) begin
                $fatal(
                    1,
                    "%s: Full mismatch. Expected %0b, got %0b.",
                    message, expected_full, full
                );
            end

            if (empty !== expected_empty) begin
                $fatal(
                    1,
                    "%s: Empty mismatch. Expected %0b, got %0b.",
                    message, expected_empty, empty
                );
            end
        end
    endtask

    task automatic reset_dut();
        begin
            wr_en = 1'b0;
            rd_en = 1'b0;
            din   = '0;

            rst = 1'b1;

            repeat (2) @(posedge clk);
            #1ns;

            rst = 1'b0;
            @(posedge clk);
            #1ns;

            check_flags(1'b0, 1'b1, "after reset");
        end
    endtask

    task automatic write_fifo(
        input logic [DATA_WIDTH-1:0] value
    );
        begin
            wr_en = 1'b1;
            rd_en = 1'b0;
            din   = value;

            @(posedge clk);
            #1ns;

            wr_en = 1'b0;
            din   = '0;
        end
    endtask

    task automatic read_and_check(
        input logic [DATA_WIDTH-1:0] expected_value,
        input logic expected_full,
        input logic expected_empty,
        input string message
    );
        begin
            wr_en = 1'b0;
            rd_en = 1'b1;

            @(posedge clk);
            #1ns;

            rd_en = 1'b0;

            if (dout !== expected_value) begin
                $fatal(
                    1,
                    "%s: Dout mismatch. Expected 0x%0h, got 0x%0h.",
                    message, expected_value, dout
                );
            end

            check_flags(expected_full, expected_empty, message);
        end
    endtask

    initial begin
        logic [DATA_WIDTH-1:0] value;

        $display("Starting sync_fifo testbench");

        reset_dut();

        /*
         * Test 1:
         * Empty FIFO after reset.
         */
        check_flags(
            1'b0,
            1'b1,
            "FIFO should be empty after reset"
        );

        /*
         * Test 2:
         * Write and read a single entry.
         */
        write_fifo(8'h11);

        check_flags(
            1'b0,
            1'b0,
            "FIFO should be non-empty after one write"
        );

        read_and_check(
            8'h11,
            1'b0,
            1'b1,
            "Reading single entry 0x11"
        );

        /*
         * Test 3:
         * Fill the FIFO.
         */
        for (int i = 0; i < DEPTH; i++) begin
            value = 8'h20 + i;
            write_fifo(value);
        end

        check_flags(
            1'b1,
            1'b0,
            "FIFO should be full after DEPTH writes"
        );

        /*
         * Test 4:
         * Drain the FIFO and verify ordering.
         */
        for (int i = 0; i < DEPTH; i++) begin
            value = 8'h20 + i;

            if (i == DEPTH - 1) begin
                read_and_check(
                    value,
                    1'b0,
                    1'b1,
                    "Reading final entry from full FIFO"
                );
            end else begin
                read_and_check(
                    value,
                    1'b0,
                    1'b0,
                    "Reading entry from full FIFO"
                );
            end
        end

        $display("All sync_fifo tests passed");
        $finish;
    end

endmodule : sync_fifo_tb
