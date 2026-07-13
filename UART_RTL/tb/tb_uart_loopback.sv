// tb_uart_loopback.sv
// Testbench boilerplate: UART TX -> UART RX loopback (3-wire).
// Connects serial_tx_* from TX DUT to serial_rx_* on RX DUT.
//
// GTKWave: inspect both DUTs in one VCD — verify bytes sent == bytes received.
//
// This is the closest end-to-end test before chip-top integration.

`timescale 1ns / 1ps

module tb_uart_loopback;

    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE      = 115_200;
    localparam int CLKS_PER_BIT   = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam real CLK_PERIOD_NS = 1_000_000_000.0 / SIM_CLOCK_FREQ;

    logic       clk;
    logic       n_rst;
    logic       output_ready;
    logic       tx_ready;
    logic       baud_tick;

    // TX side
    logic [7:0] r_out, g_out, b_out;
    logic       serial_tx_r, serial_tx_g, serial_tx_b;

    // RX side (wired from TX serial outputs)
    logic [7:0] r_px, g_px, b_px;
    logic       r_ready, g_ready, b_ready;

    // -------------------------------------------------------------------------
    // Shared clock / reset
    // -------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_loopback.vcd");
        $dumpvars(0, tb_uart_loopback);
    end

    // -------------------------------------------------------------------------
    // TX DUT
    // -------------------------------------------------------------------------
    uart_tx_top #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_tx (
        .clk          (clk),
        .n_rst        (n_rst),
        .r_out        (r_out),
        .g_out        (g_out),
        .b_out        (b_out),
        .output_ready (output_ready),
        .serial_tx_r  (serial_tx_r),
        .serial_tx_g  (serial_tx_g),
        .serial_tx_b  (serial_tx_b),
        .tx_ready     (tx_ready),
        .baud_tick    (baud_tick)
    );

    // -------------------------------------------------------------------------
    // RX DUT — serial inputs loop back from TX outputs
    // -------------------------------------------------------------------------
    uart_rx_top #(
        .CLOCK_FREQ      (SIM_CLOCK_FREQ),
        .BAUD_RATE       (BAUD_RATE),
        .USE_SHARED_BAUD (1'b1)
    ) u_rx (
        .clk              (clk),
        .n_rst            (n_rst),
        .serial_rx_r      (serial_tx_r),
        .serial_rx_g      (serial_tx_g),
        .serial_rx_b      (serial_tx_b),
        .baud_tick_shared (baud_tick),
        .output_ready     (output_ready),
        .r_px         (r_px),
        .r_ready      (r_ready),
        .g_px         (g_px),
        .g_ready      (g_ready),
        .b_px         (b_px),
        .b_ready      (b_ready)
    );

    // -------------------------------------------------------------------------
    // Reset
    // -------------------------------------------------------------------------
    task automatic apply_reset();
        n_rst         = 1'b0;
        output_ready  = 1'b0;
        r_out         = 8'h00;
        g_out         = 8'h00;
        b_out         = 8'h00;
        repeat (10) @(posedge clk);
        n_rst = 1'b1;
        repeat (5)  @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // Trigger TX send (same as tb_uart_tx). Safe while RX is not in WAIT_READY.
    // -------------------------------------------------------------------------
    task automatic send_pixel(
        input logic [7:0] r_val,
        input logic [7:0] g_val,
        input logic [7:0] b_val
    );
        wait (tx_ready == 1'b1);
        r_out = r_val;
        g_out = g_val;
        b_out = b_val;
        @(posedge clk);
        output_ready = 1'b1;
        @(posedge clk);
        output_ready = 1'b0;
        wait (tx_ready == 1'b0);
        wait (tx_ready == 1'b1);
        $display("t=%0t TX sent R=%02h G=%02h B=%02h", $time, r_val, g_val, b_val);
    endtask

    // -------------------------------------------------------------------------
    // Wait until all RX channels have a complete byte (WAIT_READY state).
    // -------------------------------------------------------------------------
    task automatic wait_rx_ready(
        input logic [7:0] r_exp,
        input logic [7:0] g_exp,
        input logic [7:0] b_exp
    );
        int timeout;
        logic done;
        timeout = 0;
        done    = 1'b0;
        while (!done && timeout < 2000) begin
            @(posedge clk);
            if (r_ready && g_ready && b_ready &&
                r_px == r_exp && g_px == g_exp && b_px == b_exp)
                done = 1'b1;
            timeout++;
        end
        if (!done)
            $display("TIMEOUT waiting for RX pixels at t=%0t (r_ready=%b r_px=%02h)",
                     $time, r_ready, r_px);
    endtask

    // -------------------------------------------------------------------------
    // Ack RX — release WAIT_READY. Only call after checking px values.
    // -------------------------------------------------------------------------
    task automatic ack_rx();
        // Avoid re-triggering TX with a second frame during ack
        r_out = 8'h00;
        g_out = 8'h00;
        b_out = 8'h00;
        @(posedge clk);
        output_ready = 1'b1;
        @(posedge clk);
        output_ready = 1'b0;
    endtask

    // -------------------------------------------------------------------------
    // Main test
    // -------------------------------------------------------------------------
    initial begin
        n_rst        = 1'b0;
        output_ready = 1'b0;
        r_out        = 8'h00;
        g_out        = 8'h00;
        b_out        = 8'h00;

        $display("=== tb_uart_loopback: start ===");
        apply_reset();

        // Step 1: TX -> serial loopback -> RX (RX ignores output_ready until WAIT_READY)
        send_pixel(8'h12, 8'h34, 8'h56);

        // Step 2: wait until all three bytes received correctly
        wait_rx_ready(8'h12, 8'h34, 8'h56);

        // Step 3: verify BEFORE ack — px_out holds the received byte in WAIT_READY
        if (r_px == 8'h12 && g_px == 8'h34 && b_px == 8'h56)
            $display("PASS: loopback bytes match (R=%02h G=%02h B=%02h)", r_px, g_px, b_px);
        else
            $display("FAIL: expected 12/34/56, got R=%02h G=%02h B=%02h", r_px, g_px, b_px);

        // Step 4: release RX channels (mimics pixel_controller ack)
        ack_rx();

        $display("=== tb_uart_loopback: done ===");
        repeat (500) @(posedge clk);
        $finish;
    end

endmodule
