// tb_uart_rx_byte.sv
// unit TB for one RX channel (own baud gen)
// bit-bangs a couple frames onto serial_rx

`timescale 1ns / 1ps

module tb_uart_rx_byte;

    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE = 115_200;
    localparam int CLKS_PER_BIT = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS = CLKS_PER_BIT / 2;
    localparam real CLK_PERIOD_NS = 1000.0;

    logic clk, n_rst;
    logic serial_rx;
    logic output_ready;
    logic [7:0] px_out;
    logic px_ready;
    int error_count;

    uart_rx_byte #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .USE_SHARED_BAUD(1'b0)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx(serial_rx),
        .baud_tick_shared(1'b0),
        .output_ready(output_ready),
        .px_out(px_out),
        .px_ready(px_ready)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_rx_byte.vcd");
        $dumpvars(0, tb_uart_rx_byte);
    end

    task automatic drive_byte(input logic [7:0] data, input logic stop_bit);
        serial_rx = 0;
        repeat (CLKS_PER_BIT) @(posedge clk);
        for (int i = 0; i < 8; i++) begin
            serial_rx = data[i];
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
        serial_rx = stop_bit;
        repeat (CLKS_PER_BIT) @(posedge clk);
        serial_rx = 1;
    endtask

    task automatic wait_ready(input int timeout);
        int t;
        t = 0;
        while (!px_ready && t < timeout) begin
            @(posedge clk);
            t++;
        end
        if (!px_ready) begin
            $error("timeout waiting for px_ready");
            error_count++;
        end
    endtask

    task automatic ack();
        @(posedge clk);
        output_ready = 1;
        @(posedge clk);
        output_ready = 0;
        wait (!px_ready);
    endtask

    initial begin
        error_count = 0;
        n_rst = 0;
        serial_rx = 1;
        output_ready = 0;

        $display("=== tb_uart_rx_byte: start ===");

        repeat (5) @(posedge clk);
        n_rst = 1;
        repeat (5) @(posedge clk);

        // glitch
        serial_rx = 0;
        repeat (2) @(posedge clk);
        serial_rx = 1;
        repeat (CLKS_PER_BIT + HALF_CLKS) @(posedge clk);
        if (px_ready) begin
            $error("false start asserted ready");
            error_count++;
        end else
            $display("PASS: false start ignored");

        // good byte
        drive_byte(8'hC3, 1'b1);
        wait_ready(5000);
        if (px_out !== 8'hC3) begin
            $error("expected C3 got %02h", px_out);
            error_count++;
        end else
            $display("PASS: got C3");
        ack();
        repeat (20) @(posedge clk);

        // second byte
        drive_byte(8'h5A, 1'b1);
        wait_ready(5000);
        if (px_out !== 8'h5A) begin
            $error("expected 5A got %02h", px_out);
            error_count++;
        end else
            $display("PASS: got 5A");
        ack();

        // bad stop
        drive_byte(8'h11, 1'b0);
        repeat (CLKS_PER_BIT * 2) @(posedge clk);
        if (px_ready) begin
            $error("bad stop should not ready");
            error_count++;
        end else
            $display("PASS: bad stop rejected");
        serial_rx = 1;
        repeat (CLKS_PER_BIT * 12) @(posedge clk);
        if (px_ready)
            ack();

        if (error_count == 0)
            $display("=== tb_uart_rx_byte: PASS ===");
        else
            $fatal(1, "=== tb_uart_rx_byte: FAIL (%0d) ===", error_count);

        $finish;
    end

endmodule
