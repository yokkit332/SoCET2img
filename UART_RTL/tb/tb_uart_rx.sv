// tb_uart_rx.sv
// Testbench boilerplate for uart_rx_top (3-wire RGB UART RX).
//
// GTKWave flow:
//   1. Run simulator to produce tb_uart_rx.vcd
//   2. gtkwave tb_uart_rx.vcd
//   3. Add signals: serial_rx_r/g/b, r_px/g_px/b_px, r_ready/g_ready/b_ready
//
// NOTE: You must bit-bang UART frames onto serial_rx_r/g/b in a task.
//       Each bit lasts CLKS_PER_BIT clock cycles.

`timescale 1ns / 1ps

module tb_uart_rx;

    // -------------------------------------------------------------------------
    // Simulation parameters
    // -------------------------------------------------------------------------
    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE      = 115_200;
    localparam int CLKS_PER_BIT   = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam real CLK_PERIOD_NS = 1_000_000_000.0 / SIM_CLOCK_FREQ;

    // -------------------------------------------------------------------------
    // DUT inputs / outputs
    // -------------------------------------------------------------------------
    logic       clk;
    logic       n_rst;
    logic       serial_rx_r;
    logic       serial_rx_g;
    logic       serial_rx_b;
    logic       output_ready;
    logic [7:0] r_px;
    logic       r_ready;
    logic [7:0] g_px;
    logic       g_ready;
    logic [7:0] b_px;
    logic       b_ready;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    uart_rx_top #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk              (clk),
        .n_rst            (n_rst),
        .serial_rx_r      (serial_rx_r),
        .serial_rx_g      (serial_rx_g),
        .serial_rx_b      (serial_rx_b),
        .baud_tick_shared (1'b0),
        .output_ready     (output_ready),
        .r_px         (r_px),
        .r_ready      (r_ready),
        .g_px         (g_px),
        .g_ready      (g_ready),
        .b_px         (b_px),
        .b_ready      (b_ready)
    );

    // -------------------------------------------------------------------------
    // Clock generation
    // -------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // VCD waveform dump for GTKWave
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);
    end

    // -------------------------------------------------------------------------
    // Idle UART lines are high
    // -------------------------------------------------------------------------
    initial begin
        serial_rx_r = 1'b1;
        serial_rx_g = 1'b1;
        serial_rx_b = 1'b1;
    end

    // -------------------------------------------------------------------------
    // Reset sequence
    // -------------------------------------------------------------------------
    task automatic apply_reset();
        n_rst        = 1'b0;
        output_ready = 1'b0;
        repeat (10) @(posedge clk);
        n_rst = 1'b1;
        repeat (5)  @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // TODO: Task — drive one UART byte on a serial line (testbench acts as host)
    // Frame: START(0) -> 8 data bits LSB first -> STOP(1)
    // Hint: hold each bit for CLKS_PER_BIT clock cycles using @(posedge clk) repeats
    // -------------------------------------------------------------------------
    task automatic drive_uart_r(input logic [7:0] data);
        serial_rx_r = 1'b0;
        repeat (CLKS_PER_BIT) @(posedge clk);
        for (int i = 0; i < 8; i++) begin
            serial_rx_r = data[i];
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
        serial_rx_r = 1'b1;
        repeat (CLKS_PER_BIT) @(posedge clk);
    endtask

    task automatic drive_uart_g(input logic [7:0] data);
        serial_rx_g = 1'b0;
        repeat (CLKS_PER_BIT) @(posedge clk);
        for (int i = 0; i < 8; i++) begin
            serial_rx_g = data[i];
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
        serial_rx_g = 1'b1;
        repeat (CLKS_PER_BIT) @(posedge clk);
    endtask

    task automatic drive_uart_b(input logic [7:0] data);
        serial_rx_b = 1'b0;
        repeat (CLKS_PER_BIT) @(posedge clk);
        for (int i = 0; i < 8; i++) begin
            serial_rx_b = data[i];
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
        serial_rx_b = 1'b1;
        repeat (CLKS_PER_BIT) @(posedge clk);
    endtask

    task automatic ack_pixel();
        @(posedge clk);
        output_ready = 1'b1;
        @(posedge clk);
        output_ready = 1'b0;
    endtask

    // -------------------------------------------------------------------------
    // TODO: Optional — auto-ack when all channels ready
    // -------------------------------------------------------------------------
    // always @(posedge clk) begin
    //     if (r_ready && g_ready && b_ready)
    //         output_ready <= 1'b1;
    //     else
    //         output_ready <= 1'b0;
    // end

    // -------------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------------
    initial begin
        $display("=== tb_uart_rx: start ===");
        $display("SIM_CLOCK_FREQ=%0d Hz  BAUD_RATE=%0d  CLKS_PER_BIT=%0d",
                 SIM_CLOCK_FREQ, BAUD_RATE, CLKS_PER_BIT);

        apply_reset();

        fork
            drive_uart_r(8'h12);
            drive_uart_g(8'h34);
            drive_uart_b(8'h56);
        join

        wait (r_ready && g_ready && b_ready);

        if (r_px == 8'h12 && g_px == 8'h34 && b_px == 8'h56)
            $display("PASS: RX bytes match");
        else
            $display("FAIL: got R=%02h G=%02h B=%02h", r_px, g_px, b_px);

        ack_pixel();

        $display("=== tb_uart_rx: done ===");
        repeat (200) @(posedge clk);
        $finish;
    end

endmodule
