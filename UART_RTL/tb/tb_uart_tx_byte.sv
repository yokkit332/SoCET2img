// tb_uart_tx_byte.sv
// unit TB for one TX channel
// uses a real baud_generator, checks start/data/stop on serial_tx

`timescale 1ns / 1ps

module tb_uart_tx_byte;

    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE = 115_200;
    localparam int CLKS_PER_BIT = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS = CLKS_PER_BIT / 2;
    localparam real CLK_PERIOD_NS = 1000.0;

    logic clk, n_rst;
    logic baud_tick;
    logic [7:0] px_in;
    logic output_ready;
    logic serial_tx, tx_ready, baud_resync;
    logic sync_reset;
    int error_count;

    // shared baud like the real top (resync from the byte)
    assign sync_reset = baud_resync;

    baud_generator #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud (
        .clk(clk),
        .n_rst(n_rst),
        .sync_reset(sync_reset),
        .baud_tick(baud_tick)
    );

    uart_tx_byte #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .baud_tick(baud_tick),
        .px_in(px_in),
        .output_ready(output_ready),
        .serial_tx(serial_tx),
        .tx_ready(tx_ready),
        .baud_resync(baud_resync)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_tx_byte.vcd");
        $dumpvars(0, tb_uart_tx_byte);
    end

    task automatic send_byte(input logic [7:0] data);
        wait (tx_ready);
        px_in = data;
        @(posedge clk);
        output_ready = 1;
        @(posedge clk);
        output_ready = 0;
    endtask

    // sample one UART frame off serial_tx
    task automatic check_byte(input logic [7:0] expected);
        logic [7:0] got;
        int t;
        logic ok;
        ok = 1;
        t = 0;
        while (serial_tx !== 0 && t < 5000) begin
            @(posedge clk);
            t++;
        end
        if (serial_tx !== 0) begin
            $error("timeout waiting for start");
            error_count++;
            ok = 0;
        end

        if (ok) begin
            repeat (HALF_CLKS) @(posedge clk);
            if (serial_tx !== 0) begin
                $error("start midbit not 0");
                error_count++;
                ok = 0;
            end
        end

        if (ok) begin
            for (int i = 0; i < 8; i++) begin
                repeat (CLKS_PER_BIT) @(posedge clk);
                got[i] = serial_tx;
            end

            repeat (CLKS_PER_BIT) @(posedge clk);
            if (serial_tx !== 1) begin
                $error("stop not 1");
                error_count++;
                ok = 0;
            end
        end

        if (ok) begin
            if (got !== expected) begin
                $error("got %02h expected %02h", got, expected);
                error_count++;
            end else
                $display("PASS: byte %02h", got);
        end
    endtask

    initial begin
        error_count = 0;
        n_rst = 0;
        px_in = 0;
        output_ready = 0;

        $display("=== tb_uart_tx_byte: start ===");

        repeat (5) @(posedge clk);
        n_rst = 1;
        repeat (5) @(posedge clk);

        if (!tx_ready) begin
            $error("not ready after reset");
            error_count++;
        end

        fork
            check_byte(8'hA5);
            begin
                @(posedge clk);
                send_byte(8'hA5);
            end
        join

        wait (tx_ready);
        repeat (20) @(posedge clk);

        fork
            check_byte(8'h5A);
            begin
                @(posedge clk);
                send_byte(8'h5A);
            end
        join

        if (error_count == 0)
            $display("=== tb_uart_tx_byte: PASS ===");
        else
            $fatal(1, "=== tb_uart_tx_byte: FAIL (%0d) ===", error_count);

        $finish;
    end

endmodule
