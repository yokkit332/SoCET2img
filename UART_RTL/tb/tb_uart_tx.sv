// tb_uart_tx.sv
// Testbench boilerplate for uart_tx_top (3-wire RGB UART TX).
//
// GTKWave flow (after simulation):
//   1. Run simulator to produce tb_uart_tx.vcd
//   2. gtkwave tb_uart_tx.vcd
//   3. Add signals: serial_tx_r/g/b, r_out/g_out/b_out, output_ready, tx_ready
//
// Compile hint (Verilator example):
//   verilator --binary --trace -CFLAGS "-std=c++14" \
//     -I../uart ../uart/*.sv tb_uart_tx.sv
//
// Compile hint (Icarus example, if your build includes all ../uart/*.sv):
//   iverilog -g2012 -o sim_tx ../uart/*.sv tb_uart_tx.sv
//   vvp sim_tx
//
// NOTE: SIM_CLOCK_FREQ is lower than the 66 MHz FPGA clock so simulation runs
//       faster. DUT parameters are overridden below — baud rate stays 115200.

`timescale 1ns / 1ps

module tb_uart_tx;

    // -------------------------------------------------------------------------
    // Simulation parameters (override FPGA 66 MHz for faster sim)
    // -------------------------------------------------------------------------
    localparam int SIM_CLOCK_FREQ = 1_000_000;   // 1 MHz sim clock
    localparam int BAUD_RATE      = 115_200;
    localparam int CLKS_PER_BIT   = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam real CLK_PERIOD_NS = 1_000_000_000.0 / SIM_CLOCK_FREQ;

    // -------------------------------------------------------------------------
    // DUT inputs / outputs
    // -------------------------------------------------------------------------
    logic       clk;
    logic       n_rst;
    logic [7:0] r_out;
    logic [7:0] g_out;
    logic [7:0] b_out;
    logic       output_ready;
    logic       serial_tx_r;
    logic       serial_tx_g;
    logic       serial_tx_b;
    logic       tx_ready;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    uart_tx_top #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk          (clk),
        .n_rst        (n_rst),
        .r_out        (r_out),
        .g_out        (g_out),
        .b_out        (b_out),
        .output_ready (output_ready),
        .serial_tx_r  (serial_tx_r),
        .serial_tx_g  (serial_tx_g),
        .serial_tx_b  (serial_tx_b),
        .tx_ready     (tx_ready)
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
        $dumpfile("tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
    end

    // -------------------------------------------------------------------------
    // Reset sequence
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
    // TODO: Task — send one RGB pixel (3 bytes) through TX
    // Hint:
    //   1. Wait until tx_ready == 1
    //   2. Drive r_out, g_out, b_out with test values
    //   3. Pulse output_ready for one clock cycle
    //   4. Wait for tx_ready to return high (transmission complete)
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
        $display("t=%0t sent pixel R=%02h G=%02h B=%02h", $time, r_val, g_val, b_val);
    endtask

    // -------------------------------------------------------------------------
    // TODO: Optional monitor — print when serial lines change (debug aid)
    // -------------------------------------------------------------------------
    // initial begin
    //     $monitor("t=%0t tx_r=%b tx_g=%b tx_b=%b tx_ready=%b out_rdy=%b",
    //              $time, serial_tx_r, serial_tx_g, serial_tx_b, tx_ready, output_ready);
    // end

    // -------------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------------
    initial begin
        n_rst        = 1'b0;
        output_ready = 1'b0;
        r_out        = 8'h00;
        g_out        = 8'h00;
        b_out        = 8'h00;

        $display("=== tb_uart_tx: start ===");
        $display("SIM_CLOCK_FREQ=%0d Hz  BAUD_RATE=%0d  CLKS_PER_BIT=%0d",
                 SIM_CLOCK_FREQ, BAUD_RATE, CLKS_PER_BIT);

        apply_reset();

        // Test 1 — single pixel (easy patterns to spot in GTKWave)
        send_pixel(8'hAA, 8'hBB, 8'hCC);
        repeat (100) @(posedge clk);

        // Test 2 — back-to-back pixel
        send_pixel(8'hDD, 8'hEE, 8'hFF);
        repeat (100) @(posedge clk);

        // In GTKWave, verify per channel:
        //   IDLE high -> START(0) -> 8 data bits LSB first -> STOP(1)

        $display("=== tb_uart_tx: done ===");
        repeat (100) @(posedge clk);
        $finish;
    end

endmodule
