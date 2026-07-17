`timescale 10ns/10ps

/*
* Steps: 
* 1. Define localparams & logic signals (wires) for the DUTs
* 2. Instantiate DUTs
* 3. Set the clock signal(s)
* 4. Define tasks
*   4.1 Assert statements for error checking
* 5. Initial-begin block
*   5.1 Create intermediate logic signals (wires)
*   5.2 Write the tests: Set values, run tasks, then check outputs
*/

module uart_tb;
    localparam int CLKS_PER_BIT = 87;
    localparam int CLK_FREQ = 10_000_000;
    localparam time CLK_PERIOD = 100ns;

    // clk and reset signals
    logic clk = 1'b0;
    logic rst_rx = 1'b0;
    logic rst_tx = 1'b0;

    // Packet to transmit and receive
    logic [7:0] pkt_tx = '0;
    logic [7:0] pkt_rx = '0;

    // Data line
    logic data = 1'b0;

    // Busy signals
    logic tx_busy = 1'b0;
    logic rx_busy = 1'b0;

    // Valid signals
    logic tx_valid = 1'b0;
    logic pkt_valid = 1'b0;     // RX packet received valid?

    // Misc. signals
    logic tx_ready = 1'b0;
    logic corrupt = 1'b0;

    // Instantiate UART RX module
    uart_rx #(
        .CLK_FREQ(CLK_FREQ), 
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx (
        .clk(clk),
        .rst(rst_rx),
        .rx_serial(data),
        .pkt(pkt_rx),
        .busy(rx_busy),
        .corrupt(corrupt),
        .pkt_valid(pkt_valid)
    );

    // Instantiate UART TX module
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx (
        .clk(clk),
        .rst(rst_tx),
        .pkt(pkt_tx),
        .tx_serial(data),
        .busy(tx_busy),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready)
    );

    // Define clk signal 10 MHz
    always #(CLK_PERIOD / 2) clk = ~clk;

    task automatic transmit(
        input logic [7:0] pkt_in,
        input logic tx_valid_in
    );
        begin
            pkt_tx <= pkt_in;               // Should I use non-blocking here?
            tx_valid <= tx_valid_in;

            if (tx_valid_in === 1'b1) $display("START transmitting transmission soon with byte: 0x%0h ." 
                                            , pkt_in);
        end
    endtask

    task automatic check_flags_tx(
        input logic expected_tx_ready,
        input logic expected_busy
    );
        begin
            assert(tx_busy === expected_busy)
            else $fatal (1, "Busy flag mismatch. Expected %0b, received, %0b",
                expected_busy, tx_busy);

            assert(tx_ready === expected_tx_ready)
            else $fatal(1, "tx_ready mismatch. Expected %0b, received %0b.",
                expected_tx_ready, tx_ready);
        end
    endtask

    task automatic check_out_rx(
        input logic [7:0] expected_pkt_out,
        input logic expected_pkt_valid
    );
        begin
            assert (pkt_rx === expected_pkt_out)
            else $fatal(1, "Packet output at RX mismatch. Expected 0x%0h, received 0x%0h.",
                expected_pkt_out, pkt_rx);
            
            assert (pkt_valid === expected_pkt_valid)
            else $fatal(1, "Pkt_valid mismatch. expected %0b, received %0b.",
                expected_pkt_valid, pkt_valid);
        end
    endtask

    task automatic check_flags_rx(
        input logic expected_busy,
        input logic expected_corrupt
    );
        begin
            assert(expected_busy === rx_busy)
            else $fatal(1, "Busy RX mismatch. Expected %0b, received %0b.",
                expected_busy, rx_busy);

            assert(expected_corrupt === corrupt)
            else $fatal(1, "Corrupt mismatch. Expected %0b, received %0b.",
                expected_corrupt, corrupt);
        end
    endtask

    task automatic reset_rx_tx();
        begin
        rst_rx = 1'b1;
        rst_tx = 1'b1;

        @(posedge clk);
        #100ns;
        end
    endtask

    task automatic wait_bit(
        input logic start_tx        // 1 for start of transmission, 0 for middle of transmission
    );
    begin
        const time WAIT_TIME = 8700ns;  // time vs realtime types?
        @(posedge clk);
        #1ns;
        if (start_tx === 1'b1) begin
            // Added 2 cycle latency due to 2-flop synchronizer in RX
            #WAIT_TIME;
            #200ns;
        else 
            #WAIT_TIME;
        end
    endtask

    initial begin
        $display("Beginning test cases...");

        reset_rx_tx();

        @(posedge clk);
        #10ns;

        /*
        * Test 1:
        * No write, test flags
        */

        tx_valid = 1'b0;
        pkt = '0;

        // TX should be ready and not busy
        check_flags_tx(
            1'b1,
            1'b0
        );

        // RX should not be busy nor corrupt
        check_flags_rx(
            1'b0,
            1'b0
        );

       @(posedge clk)
       #100ns; 

        /*
        * Test 2:
        * Write 1 byte over UART
        */

        transmit (8'hFF, 1'b1);
        // 1 cycle latency due to START state owning start bit
        @(posedge clk);
        #100ns;

        wait_bit(1'b1);     // Wait to receive start bit
        check_flags_tx(1'b0, 1'b1);
        check_flags_rx(1'b1, 1'b0);

        // Wait for transmission and STOP bits
        for (int i = 0; i < 9; i++) begin
            wait_bit(1'b0);
        end 

        // Wait 1.5 bit times due to mid bit sampling in RX +10 ns for safety
        @(posedge clk);
        #4360ns;

        // RX should not be busy or corrupt
        check_flags_rx(1'b0, 1'b0);

        // TX should be ready and not busy
        check_flags_tx(1'b1, 1'b0);

        // Expected pkt and expected pkt_valid
        check_out_rx(8'hFF, 1'b1);

    end

endmodule : uart_tb
