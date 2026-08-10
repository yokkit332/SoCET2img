// tb_uart_rgb_serializer.sv
// Self-checking TB: feed one RGB pixel, decode serial_tx framing/order

`timescale 1ns / 1ps

module tb_uart_rgb_serializer;

    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE      = 115_200;
    localparam int CLKS_PER_BIT   = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS      = CLKS_PER_BIT / 2;
    localparam real CLK_PERIOD_NS = 1000.0;

    logic       clk;
    logic       n_rst;
    logic [7:0] red_in, green_in, blue_in;
    logic       pixel_valid;
    logic       pixel_ready;
    logic       serial_tx;
    logic       busy;
    logic       pixel_done;

    int error_count;

    uart_rgb_serializer #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .red_in(red_in),
        .green_in(green_in),
        .blue_in(blue_in),
        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready),
        .serial_tx(serial_tx),
        .busy(busy),
        .pixel_done(pixel_done)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_rgb_serializer.vcd");
        $dumpvars(0, tb_uart_rgb_serializer);
    end

    // decode one UART byte from serial_tx (LSB first)
    task automatic recv_uart_byte(output logic [7:0] got);
        int t;
        logic ok;
        ok  = 1'b1;
        t   = 0;
        got = 8'h00;

        while (serial_tx !== 1'b0 && t < 20000) begin
            @(posedge clk);
            t++;
        end
        if (serial_tx !== 1'b0) begin
            $error("timeout waiting for START");
            error_count++;
            ok = 1'b0;
        end

        if (ok) begin
            // mid-start should still be low
            repeat (HALF_CLKS) @(posedge clk);
            if (serial_tx !== 1'b0) begin
                $error("START mid-bit not 0");
                error_count++;
                ok = 1'b0;
            end
        end

        if (ok) begin
            for (int i = 0; i < 8; i++) begin
                repeat (CLKS_PER_BIT) @(posedge clk);
                got[i] = serial_tx;
            end

            repeat (CLKS_PER_BIT) @(posedge clk);
            if (serial_tx !== 1'b1) begin
                $error("STOP not 1");
                error_count++;
                ok = 1'b0;
            end
        end

        if (ok)
            $display("PASS: UART byte %02h framed OK", got);
    endtask

    initial begin
        error_count  = 0;
        n_rst        = 0;
        red_in       = 0;
        green_in     = 0;
        blue_in      = 0;
        pixel_valid  = 0;

        $display("=== tb_uart_rgb_serializer: start ===");

        repeat (5) @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        repeat (5) @(posedge clk);

        if (busy) begin
            $error("busy high after reset");
            error_count++;
        end

        // offer pixel 12 34 56
        @(negedge clk);
        red_in      = 8'h12;
        green_in    = 8'h34;
        blue_in     = 8'h56;
        pixel_valid = 1;

        // expect pixel_ready pulse and busy rising
        begin
            logic saw_ready;
            saw_ready = 0;
            fork
                begin
                    @(posedge clk);
                    while (!pixel_ready) @(posedge clk);
                    saw_ready = 1;
                end
                begin
                    // after ready, drop valid and try to overwrite while busy
                    while (!busy) @(posedge clk);
                    @(negedge clk);
                    pixel_valid = 0;
                    red_in   = 8'hFF;
                    green_in = 8'hFF;
                    blue_in  = 8'hFF;
                    pixel_valid = 1; // should be ignored while busy
                end
            join
            if (!saw_ready) begin
                $error("pixel_ready not seen");
                error_count++;
            end else
                $display("PASS: pixel_ready pulsed");
        end

        if (!busy) begin
            $error("busy not asserted during TX");
            error_count++;
        end else
            $display("PASS: busy during TX");

        // decode R, G, B in order
        begin
            logic [7:0] b0, b1, b2;
            logic saw_done;
            saw_done = 0;

            fork
                begin
                    recv_uart_byte(b0);
                    recv_uart_byte(b1);
                    recv_uart_byte(b2);
                end
                begin
                    @(posedge clk);
                    while (!pixel_done) @(posedge clk);
                    saw_done = 1;
                end
            join

            if (b0 !== 8'h12 || b1 !== 8'h34 || b2 !== 8'h56) begin
                $error("byte order got %02h %02h %02h expected 12 34 56", b0, b1, b2);
                error_count++;
            end else
                $display("PASS: order 12 34 56 (overwrite ignored)");

            if (!saw_done) begin
                $error("pixel_done not seen");
                error_count++;
            end else
                $display("PASS: pixel_done pulsed");
        end

        @(negedge clk);
        pixel_valid = 0;
        repeat (5) @(posedge clk);

        if (busy) begin
            $error("busy still high after done");
            error_count++;
        end else
            $display("PASS: busy cleared");

        if (error_count == 0)
            $display("=== tb_uart_rgb_serializer: PASS ===");
        else
            $fatal(1, "=== tb_uart_rgb_serializer: FAIL (%0d) ===", error_count);

        $finish;
    end

endmodule
