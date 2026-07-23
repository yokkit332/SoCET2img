// tb_uart_rx_sync.sv
// unit TB for the 2FF synchronizer
// checks reset idle high and that async input shows up 2 clocks later

`timescale 1ns / 1ps

module tb_uart_rx_sync;

    localparam real CLK_PERIOD_NS = 10.0;

    logic clk, n_rst;
    logic serial_rx_async;
    logic serial_rx_sync;
    int error_count;

    uart_rx_sync dut (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx_async(serial_rx_async),
        .serial_rx_sync(serial_rx_sync)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_rx_sync.vcd");
        $dumpvars(0, tb_uart_rx_sync);
    end

    initial begin
        error_count = 0;
        n_rst = 0;
        serial_rx_async = 0; // drive low while in reset

        $display("=== tb_uart_rx_sync: start ===");

        repeat (4) @(posedge clk);
        // still in reset -> should be idle high
        if (serial_rx_sync !== 1) begin
            $error("during reset sync should be 1, got %b", serial_rx_sync);
            error_count++;
        end else
            $display("PASS: reset holds idle high");

        n_rst = 1;
        serial_rx_async = 1;
        repeat (3) @(posedge clk);

        // drop async input, sync should follow after 2 clocks
        @(posedge clk);
        serial_rx_async = 0;
        @(posedge clk); // first flop catches it
        if (serial_rx_sync !== 1) begin
            $error("sync flipped too early (1 clock)");
            error_count++;
        end
        @(posedge clk); // second flop
        if (serial_rx_sync !== 0) begin
            $error("sync didnt go low after 2 clocks, got %b", serial_rx_sync);
            error_count++;
        end else
            $display("PASS: low after 2 clocks");

        // and back high
        @(posedge clk);
        serial_rx_async = 1;
        @(posedge clk);
        @(posedge clk);
        if (serial_rx_sync !== 1) begin
            $error("sync didnt go high after 2 clocks");
            error_count++;
        end else
            $display("PASS: high after 2 clocks");

        if (error_count == 0)
            $display("=== tb_uart_rx_sync: PASS ===");
        else
            $fatal(1, "=== tb_uart_rx_sync: FAIL (%0d) ===", error_count);

        $finish;
    end

endmodule
