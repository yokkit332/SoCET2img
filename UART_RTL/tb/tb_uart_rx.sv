// tb_uart_rx.sv
// self checking TB for uart_rx_top
// covers false start, framing error, happy path, back to back, staggered

`timescale 1ns / 1ps

module tb_uart_rx;

    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE = 115_200;
    localparam int CLKS_PER_BIT = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS = CLKS_PER_BIT / 2;
    localparam real CLK_PERIOD_NS = 1_000_000_000.0 / SIM_CLOCK_FREQ;

    logic clk;
    logic n_rst;
    logic serial_rx_r, serial_rx_g, serial_rx_b;
    logic output_ready;
    logic [7:0] r_px, g_px, b_px;
    logic r_ready, g_ready, b_ready;

    int error_count;

    uart_rx_top #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx_r(serial_rx_r),
        .serial_rx_g(serial_rx_g),
        .serial_rx_b(serial_rx_b),
        .baud_tick_shared(1'b0), // not using shared baud here
        .output_ready(output_ready),
        .r_px(r_px),
        .r_ready(r_ready),
        .g_px(g_px),
        .g_ready(g_ready),
        .b_px(b_px),
        .b_ready(b_ready)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);
    end

    // lines idle high
    initial begin
        serial_rx_r = 1;
        serial_rx_g = 1;
        serial_rx_b = 1;
    end

    task automatic apply_reset();
        n_rst = 0;
        output_ready = 0;
        serial_rx_r = 1;
        serial_rx_g = 1;
        serial_rx_b = 1;
        repeat (10) @(posedge clk);
        n_rst = 1;
        repeat (5) @(posedge clk);
    endtask

    // bit bang a UART frame onto one channel
    // ch: 0=R 1=G 2=B
    task automatic drive_uart_ch(
        input int ch,
        input logic [7:0] data,
        input logic stop_bit
    );
        // start bit
        if (ch == 0) serial_rx_r = 0;
        else if (ch == 1) serial_rx_g = 0;
        else serial_rx_b = 0;
        repeat (CLKS_PER_BIT) @(posedge clk);

        // data LSB first
        for (int i = 0; i < 8; i++) begin
            if (ch == 0) serial_rx_r = data[i];
            else if (ch == 1) serial_rx_g = data[i];
            else serial_rx_b = data[i];
            repeat (CLKS_PER_BIT) @(posedge clk);
        end

        // stop
        if (ch == 0) serial_rx_r = stop_bit;
        else if (ch == 1) serial_rx_g = stop_bit;
        else serial_rx_b = stop_bit;
        repeat (CLKS_PER_BIT) @(posedge clk);

        // back to idle
        if (ch == 0) serial_rx_r = 1;
        else if (ch == 1) serial_rx_g = 1;
        else serial_rx_b = 1;
    endtask

    // short low pulse that should get rejected
    task automatic drive_false_start_r();
        serial_rx_r = 0;
        repeat (2) @(posedge clk);
        serial_rx_r = 1;
        repeat (CLKS_PER_BIT + HALF_CLKS) @(posedge clk);
    endtask

    task automatic ack_pixel();
        @(posedge clk);
        output_ready = 1;
        @(posedge clk);
        output_ready = 0;
        wait (!r_ready && !g_ready && !b_ready);
    endtask

    task automatic wait_all_ready(input int timeout_clks);
        int t;
        t = 0;
        while (!(r_ready && g_ready && b_ready) && t < timeout_clks) begin
            @(posedge clk);
            t++;
        end
        if (!(r_ready && g_ready && b_ready)) begin
            $error("t=%0t timeout waiting for r/g/b ready", $time);
            error_count++;
        end
    endtask

    task automatic check_rgb(
        input logic [7:0] r_exp,
        input logic [7:0] g_exp,
        input logic [7:0] b_exp,
        input string tag
    );
        if (r_px === r_exp && g_px === g_exp && b_px === b_exp)
            $display("PASS: %s R=%02h G=%02h B=%02h", tag, r_px, g_px, b_px);
        else begin
            $error("FAIL: %s expected %02h/%02h/%02h got %02h/%02h/%02h",
                   tag, r_exp, g_exp, b_exp, r_px, g_px, b_px);
            error_count++;
        end
    endtask

    initial begin
        error_count = 0;
        n_rst = 0;
        output_ready = 0;

        $display("=== tb_uart_rx: start ===");
        $display("clk=%0d baud=%0d clks/bit=%0d", SIM_CLOCK_FREQ, BAUD_RATE, CLKS_PER_BIT);

        apply_reset();

        // --- test 1: glitchy start on R, should ignore ---
        drive_false_start_r();
        repeat (CLKS_PER_BIT * 4) @(posedge clk);
        if (r_ready || g_ready || b_ready) begin
            $error("FAIL: false-start, ready went high");
            error_count++;
        end else
            $display("PASS: false-start, ready stayed low");
        repeat (20) @(posedge clk);

        // --- test 2: bad stop bit = framing error ---
        begin
            logic [7:0] bad_data;
            bad_data = 8'h77;
            serial_rx_r = 0;
            repeat (CLKS_PER_BIT) @(posedge clk);
            for (int i = 0; i < 8; i++) begin
                serial_rx_r = bad_data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end
            serial_rx_r = 0; // bad stop
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
        if (r_ready) begin
            $error("FAIL: framing, r_ready asserted after bad STOP");
            error_count++;
        end else
            $display("PASS: framing, r_ready stayed low");

        // line was low a while, give it time to settle
        serial_rx_r = 1;
        repeat (CLKS_PER_BIT * 12) @(posedge clk);
        if (r_ready)
            ack_pixel();
        repeat (20) @(posedge clk);

        // --- test 3: normal parallel RGB frame ---
        fork
            drive_uart_ch(0, 8'h12, 1'b1);
            drive_uart_ch(1, 8'h34, 1'b1);
            drive_uart_ch(2, 8'h56, 1'b1);
        join
        wait_all_ready(5000);
        check_rgb(8'h12, 8'h34, 8'h56, "frame1");
        ack_pixel();
        repeat (20) @(posedge clk);

        // --- test 4: another frame right after ---
        fork
            drive_uart_ch(0, 8'hA5, 1'b1);
            drive_uart_ch(1, 8'h5A, 1'b1);
            drive_uart_ch(2, 8'hF0, 1'b1);
        join
        wait_all_ready(5000);
        check_rgb(8'hA5, 8'h5A, 8'hF0, "frame2");
        ack_pixel();
        repeat (20) @(posedge clk);

        // --- test 5: channels start at different times ---
        fork
            begin
                drive_uart_ch(0, 8'h11, 1'b1);
            end
            begin
                repeat (CLKS_PER_BIT * 3) @(posedge clk);
                drive_uart_ch(1, 8'h22, 1'b1);
            end
            begin
                repeat (CLKS_PER_BIT * 6) @(posedge clk);
                drive_uart_ch(2, 8'h33, 1'b1);
            end
        join
        wait_all_ready(5000);
        check_rgb(8'h11, 8'h22, 8'h33, "staggered");
        ack_pixel();
        repeat (20) @(posedge clk);

        if (error_count == 0)
            $display("=== tb_uart_rx: PASS ===");
        else
            $fatal(1, "=== tb_uart_rx: FAIL (%0d errors) ===", error_count);

        repeat (50) @(posedge clk);
        $finish;
    end

endmodule
