// tb_uart_rx_fsm.sv
// unit TB for RX FSM (local baud mode)
// feeds a fake UART frame via serial_rx + baud_tick

`timescale 1ns / 1ps

module tb_uart_rx_fsm;

    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE = 115_200;
    localparam int CLKS_PER_BIT = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS = CLKS_PER_BIT / 2;
    localparam real CLK_PERIOD_NS = 1000.0;

    logic clk, n_rst;
    logic serial_rx;
    logic baud_tick;
    logic output_ready;
    logic shift_en, px_ready, baud_sync_reset;
    int error_count;

    uart_rx_fsm #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .SHARED_BAUD(1'b0)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx(serial_rx),
        .baud_tick(baud_tick),
        .output_ready(output_ready),
        .shift_en(shift_en),
        .px_ready(px_ready),
        .baud_sync_reset(baud_sync_reset)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_rx_fsm.vcd");
        $dumpvars(0, tb_uart_rx_fsm);
    end

    task automatic pulse_baud();
        @(negedge clk);
        baud_tick = 1;
        @(negedge clk);
        baud_tick = 0;
    endtask

    initial begin
        error_count = 0;
        n_rst = 0;
        serial_rx = 1;
        baud_tick = 0;
        output_ready = 0;

        $display("=== tb_uart_rx_fsm: start ===");

        repeat (5) @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        repeat (3) @(posedge clk);

        // false start: low then high again before mid-bit check passes
        @(negedge clk);
        serial_rx = 0;          // detect start
        @(posedge clk);         // enter START
        @(negedge clk);
        serial_rx = 1;          // glitch gone
        // wait for mid-bit check to send us back to IDLE
        repeat (HALF_CLKS + 3) @(posedge clk);
        if (px_ready) begin
            $error("false start set px_ready");
            error_count++;
        end else
            $display("PASS: false start rejected");

        // good frame
        @(negedge clk);
        serial_rx = 0;
        @(posedge clk); // START
        repeat (CLKS_PER_BIT) @(posedge clk);

        // 8 data samples
        for (int i = 0; i < 8; i++) begin
            @(negedge clk);
            serial_rx = i[0]; // alt bits
            pulse_baud();
        end

        // stop high
        @(negedge clk);
        serial_rx = 1;
        pulse_baud();
        @(posedge clk);
        @(posedge clk);

        if (!px_ready) begin
            $error("px_ready not set after good frame");
            error_count++;
        end else
            $display("PASS: px_ready after good frame");

        @(negedge clk);
        output_ready = 1;
        @(posedge clk);
        @(negedge clk);
        output_ready = 0;
        @(posedge clk);

        if (px_ready) begin
            $error("px_ready still high after ack");
            error_count++;
        end else
            $display("PASS: returned to idle after ack");

        // framing error
        @(negedge clk);
        serial_rx = 0;
        @(posedge clk);
        repeat (CLKS_PER_BIT) @(posedge clk);
        for (int i = 0; i < 8; i++) begin
            @(negedge clk);
            serial_rx = 1;
            pulse_baud();
        end
        @(negedge clk);
        serial_rx = 0; // bad stop
        pulse_baud();
        @(posedge clk);
        @(posedge clk);

        if (px_ready) begin
            $error("framing error should not assert px_ready");
            error_count++;
        end else
            $display("PASS: framing error rejected");

        @(negedge clk);
        serial_rx = 1;
        repeat (10) @(posedge clk);

        if (error_count == 0)
            $display("=== tb_uart_rx_fsm: PASS ===");
        else
            $fatal(1, "=== tb_uart_rx_fsm: FAIL (%0d) ===", error_count);

        $finish;
    end

endmodule
