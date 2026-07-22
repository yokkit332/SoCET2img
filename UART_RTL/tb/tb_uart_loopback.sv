// tb_uart_loopback.sv
// TX -> RX loopback with shared baud
// makes sure what we send comes back the same

`timescale 1ns / 1ps

module tb_uart_loopback;

    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE = 115_200;
    localparam int CLKS_PER_BIT = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam real CLK_PERIOD_NS = 1_000_000_000.0 / SIM_CLOCK_FREQ;

    logic clk;
    logic n_rst;
    logic tx_go;   // kick TX
    logic rx_ack;  // ack RX when we've read the pixel
    logic tx_ready;
    logic baud_tick;

    logic [7:0] r_out, g_out, b_out;
    logic serial_tx_r, serial_tx_g, serial_tx_b;

    logic [7:0] r_px, g_px, b_px;
    logic r_ready, g_ready, b_ready;

    int error_count;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_loopback.vcd");
        $dumpvars(0, tb_uart_loopback);
    end

    uart_tx_top #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_tx (
        .clk(clk),
        .n_rst(n_rst),
        .r_out(r_out),
        .g_out(g_out),
        .b_out(b_out),
        .output_ready(tx_go),
        .serial_tx_r(serial_tx_r),
        .serial_tx_g(serial_tx_g),
        .serial_tx_b(serial_tx_b),
        .tx_ready(tx_ready),
        .baud_tick(baud_tick)
    );

    // RX uses TX's baud_tick so they stay lined up
    uart_rx_top #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .USE_SHARED_BAUD(1'b1)
    ) u_rx (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx_r(serial_tx_r),
        .serial_rx_g(serial_tx_g),
        .serial_rx_b(serial_tx_b),
        .baud_tick_shared(baud_tick),
        .output_ready(rx_ack),
        .r_px(r_px),
        .r_ready(r_ready),
        .g_px(g_px),
        .g_ready(g_ready),
        .b_px(b_px),
        .b_ready(b_ready)
    );

    task automatic apply_reset();
        n_rst = 0;
        tx_go = 0;
        rx_ack = 0;
        r_out = 0;
        g_out = 0;
        b_out = 0;
        repeat (10) @(posedge clk);
        n_rst = 1;
        repeat (5) @(posedge clk);
    endtask

    task automatic send_pixel(
        input logic [7:0] r_val,
        input logic [7:0] g_val,
        input logic [7:0] b_val
    );
        wait (tx_ready == 1);
        r_out = r_val;
        g_out = g_val;
        b_out = b_val;
        @(posedge clk);
        tx_go = 1;
        @(posedge clk);
        tx_go = 0;
        wait (tx_ready == 0);
        wait (tx_ready == 1);
        $display("t=%0t TX sent R=%02h G=%02h B=%02h", $time, r_val, g_val, b_val);
    endtask

    task automatic wait_rx_ready(
        input logic [7:0] r_exp,
        input logic [7:0] g_exp,
        input logic [7:0] b_exp
    );
        int timeout;
        logic done;
        timeout = 0;
        done = 0;
        while (!done && timeout < 5000) begin
            @(posedge clk);
            if (r_ready && g_ready && b_ready)
                done = 1;
            timeout++;
        end
        if (!done) begin
            $error("TIMEOUT waiting for RX ready t=%0t (r=%b g=%b b=%b)",
                   $time, r_ready, g_ready, b_ready);
            error_count++;
        end else if (!(r_px === r_exp && g_px === g_exp && b_px === b_exp)) begin
            $error("mismatch expected %02h/%02h/%02h got %02h/%02h/%02h",
                   r_exp, g_exp, b_exp, r_px, g_px, b_px);
            error_count++;
        end else
            $display("PASS: loopback R=%02h G=%02h B=%02h", r_px, g_px, b_px);
    endtask

    task automatic ack_rx();
        @(posedge clk);
        rx_ack = 1;
        @(posedge clk);
        rx_ack = 0;
        wait (!r_ready && !g_ready && !b_ready);
    endtask

    // one full round trip
    task automatic loop_pixel(
        input logic [7:0] r_val,
        input logic [7:0] g_val,
        input logic [7:0] b_val
    );
        send_pixel(r_val, g_val, b_val);
        wait_rx_ready(r_val, g_val, b_val);
        ack_rx();
    endtask

    initial begin
        error_count = 0;
        n_rst = 0;
        tx_go = 0;
        rx_ack = 0;
        r_out = 0;
        g_out = 0;
        b_out = 0;

        $display("=== tb_uart_loopback: start ===");
        apply_reset();

        loop_pixel(8'h12, 8'h34, 8'h56);
        repeat (20) @(posedge clk);

        loop_pixel(8'hAA, 8'hBB, 8'hCC);
        repeat (20) @(posedge clk);

        // edge-ish values
        loop_pixel(8'h00, 8'hFF, 8'h55);
        repeat (20) @(posedge clk);

        if (error_count == 0)
            $display("=== tb_uart_loopback: PASS ===");
        else
            $fatal(1, "=== tb_uart_loopback: FAIL (%0d errors) ===", error_count);

        repeat (50) @(posedge clk);
        $finish;
    end

endmodule
