`timescale 1ns/1ps

module buf_tb;

    localparam int DATA_WIDTH = 8;
    localparam time CLK_PERIOD = 10;    //ns

    logic                   clk = 1'b0;
    logic                   rst = 1'b0;

    logic [DATA_WIDTH-1:0]  in_data = {DATA_WIDTH{1'b0}};
    logic                   in_valid = 1'b0;
    logic                   in_ready;

    logic [DATA_WIDTH-1:0]  out_data;
    logic                   out_valid;
    logic                   out_ready = 1'b0;

    // Should I add module before instatiation below?
    elastic_buffer #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk), 
        .rst(rst), 
        
        .in_data(in_data),
        .in_valid(in_valid),
        .in_ready(in_ready),

        .out_data(out_data),
        .out_valid(out_valid),
        .out_ready(out_ready)
        
    );

    always #(CLK_PERIOD / 2) clk = ~clk;

    task automatic check(
        input logic expected_in_ready,
        input logic expected_out_valid,
        input logic [DATA_WIDTH-1:0] expected_out_data,
        input string message
    );
        if (in_ready === expected_in_ready) begin       // Should be assert but NVC too old to compile assert
        end else begin $fatal (
                1, 
                "%s: in_ready mismatch, Expected %0b, got %0b",
                message, expected_in_ready, in_ready); end
        if (out_valid === expected_out_valid) begin
        end else begin $fatal(
                1, 
                "%s: out_valid mismatch. Expected %0b, got %0b",
                message, expected_out_valid, out_valid 
            ); end
        
        if (expected_out_valid) begin
            if(expected_out_data === out_data) begin
            end else begin $fatal(
                    1,
                    "%s: out_data mismatch. Expected 0x%0h, got 0x%0h",
                    message, expected_out_data, out_data
                ); end
        end
    endtask

    task automatic reset_dut();
        in_valid = 1'b0;
        in_data = {DATA_WIDTH{1'b0}};
        out_ready = 1'b0;

        rst = 1'b1;

        repeat (2) @(posedge clk);
        #1;
        // Ask difference between using repeat and absolute waits?
        rst = 1'b0;
        #1;

        // Ask about this and how it works, also why not assert?
        check(1'b1, 1'b0, {DATA_WIDTH{1'b0}}, "after reset");
    endtask

    initial begin
        $display("Starting ready/valid buffer test");

        reset_dut();

        /*
        Test 1:
            Buffer is empty
            Send A while downtream is not ready
            The buffer should accept A and become full
        */

        in_data = 8'h11;
        in_valid = 1'b1;
        out_ready = 1'b0;

        @(posedge clk);
        #1;

        check (
            1'b0,
            1'b1,
            8'h11,
            "After accepting A while stalled"
        );

        /*
        * Test 2:
        * Try to send B while buffer is full and downstream is stalled.
        * Since in_ready is 0, B should not be accepted.
        * Output should remain A.
        */

        in_data = 8'h22;         // Ask wouldn't B be d16?
        in_valid = 1'b1;
        out_ready = 1'b0;       // Ask isn't this redundant since already 0?

        @(posedge clk);
        #1;

        in_valid = 1'b0;
        in_data = {DATA_WIDTH{1'b0}};

        check (
            1'b0, 
            1'b1,
            8'h11,
            "B should not be accepted when stalled"
        );

        /*
        * Test 3:
        * Downstream becomes ready.
        * Current item A should transfer out.
        * No new input is accepted, so buffer becomes empty.
        */

        out_ready = 1'b1;
        in_data = {DATA_WIDTH{1'b0}};

        @(posedge clk);
        #1;

        out_ready = 1'b0;

        check (
            1'b1,
            1'b0,
            {DATA_WIDTH{1'b0}},
            "After consuming A"
        );

        /*
        * Test 4:
        * Load B into empty buffer.
        */

        in_valid = 1'b1;
        in_data = 8'h22;
        out_ready = 1'b0;

        @(posedge clk)
        #1;

        in_valid = 1'b0;
        in_data = {DATA_WIDTH{1'b0}};

        check (
            1'b0,
            1'b1,
            8'h22,
            "After accepting B"
        );

        /*
        * Test 5:
        * Simultaneous output and input.
        *
        * Buffer currently holds B.
        * Downstream is ready to consume B.
        * Upstream presents C.
        *
        * Expected result after the edge:
        * - B was consumed.
        * - C was accepted.
        * - Buffer still valid.
        * - out_data now shows C.
        */

        out_ready = 1'b1;
        in_data = 8'h33;
        in_valid = 1'b1;

        // Why this timing? Is this 1 cycle of the buffer?
        @(posedge clk)
        #1;

        in_valid = 1'b0;
        in_data = {DATA_WIDTH{1'b0}};
        out_ready = 1'b0;

        check(
            1'b0,
            1'b1,
            8'h33,
            "After simultaneous B out and C in"
        );

        /*
        * Test 6:
        * Consume C.
        */

        out_ready = 1'b1;

        @(posedge clk)
        #1;

        out_ready = 1'b0;

        check(
            1'b1,
            1'b1,
            {DATA_WIDTH{1'b0}},
            "After consuming C"
        );

        $display ("All ready/valid buffer tests passed");
        $finish;

    end

endmodule : buf_tb
