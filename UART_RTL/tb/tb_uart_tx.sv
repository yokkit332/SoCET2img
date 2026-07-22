// tb_uart_tx.sv
// basic self checking TB for uart_tx_top
// sends a couple pixels and checks the serial framing on R/G/B

`timescale 1ns / 1ps

module tb_uart_tx;

    // sped up clock so sim doesn't take forever
    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE = 115_200;
    localparam int CLKS_PER_BIT = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS = CLKS_PER_BIT / 2;
    localparam real CLK_PERIOD_NS = 1_000_000_000.0 / SIM_CLOCK_FREQ;

    logic clk;
    logic n_rst;
    logic [7:0] r_out, g_out, b_out;
    logic output_ready;
    logic serial_tx_r, serial_tx_g, serial_tx_b;
    logic tx_ready;
    logic baud_tick;

    int error_count;

    uart_tx_top #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .r_out(r_out),
        .g_out(g_out),
        .b_out(b_out),
        .output_ready(output_ready),
        .serial_tx_r(serial_tx_r),
        .serial_tx_g(serial_tx_g),
        .serial_tx_b(serial_tx_b),
        .tx_ready(tx_ready),
        .baud_tick(baud_tick)
    );

    // clock gen
    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
    end

    task automatic apply_reset();
        n_rst = 0;
        output_ready = 0;
        r_out = 0;
        g_out = 0;
        b_out = 0;
        repeat (10) @(posedge clk);
        n_rst = 1;
        repeat (5) @(posedge clk);
    endtask

    // pulse output_ready once TX is idle
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
        output_ready = 1;
        @(posedge clk);
        output_ready = 0;
        wait (tx_ready == 0);
        wait (tx_ready == 1);
        $display("t=%0t sent pixel R=%02h G=%02h B=%02h", $time, r_val, g_val, b_val);
    endtask

    // decode one UART byte off a channel (0=R 1=G 2=B)
    task automatic check_uart_byte(
        input string name,
        input int ch,
        input logic [7:0] expected
    );
        logic serial;
        logic [7:0] got;
        int timeout;
        logic ok;

        ok = 1;
        timeout = 0;
        serial = (ch == 0) ? serial_tx_r : (ch == 1) ? serial_tx_g : serial_tx_b;

        // wait for start bit (line goes low)
        while (serial !== 0 && timeout < 5000) begin
            @(posedge clk);
            serial = (ch == 0) ? serial_tx_r : (ch == 1) ? serial_tx_g : serial_tx_b;
            timeout++;
        end

        if (serial !== 0) begin
            $error("t=%0t %s: timeout waiting for START", $time, name);
            error_count++;
            ok = 0;
        end

        // sample mid-start
        if (ok) begin
            repeat (HALF_CLKS) @(posedge clk);
            serial = (ch == 0) ? serial_tx_r : (ch == 1) ? serial_tx_g : serial_tx_b;
            if (serial !== 0) begin
                $error("t=%0t %s: START mid-bit expected 0 got %b", $time, name, serial);
                error_count++;
                ok = 0;
            end
        end

        // grab 8 data bits LSB first
        if (ok) begin
            for (int i = 0; i < 8; i++) begin
                repeat (CLKS_PER_BIT) @(posedge clk);
                serial = (ch == 0) ? serial_tx_r : (ch == 1) ? serial_tx_g : serial_tx_b;
                got[i] = serial;
            end

            // stop bit should be high
            repeat (CLKS_PER_BIT) @(posedge clk);
            serial = (ch == 0) ? serial_tx_r : (ch == 1) ? serial_tx_g : serial_tx_b;
            if (serial !== 1) begin
                $error("t=%0t %s: STOP expected 1 got %b", $time, name, serial);
                error_count++;
                ok = 0;
            end
        end

        if (ok) begin
            if (got !== expected) begin
                $error("t=%0t %s: got=%02h expected=%02h", $time, name, got, expected);
                error_count++;
            end else begin
                $display("PASS: %s byte=%02h frame OK", name, got);
            end
        end
    endtask

    // send + check all 3 channels in parallel
    task automatic send_and_check(
        input logic [7:0] r_val,
        input logic [7:0] g_val,
        input logic [7:0] b_val
    );
        fork
            check_uart_byte("R", 0, r_val);
            check_uart_byte("G", 1, g_val);
            check_uart_byte("B", 2, b_val);
            begin
                @(posedge clk);
                send_pixel(r_val, g_val, b_val);
            end
        join
    endtask

    initial begin
        error_count = 0;
        n_rst = 0;
        output_ready = 0;
        r_out = 0;
        g_out = 0;
        b_out = 0;

        $display("=== tb_uart_tx: start ===");
        $display("clk=%0d baud=%0d clks/bit=%0d", SIM_CLOCK_FREQ, BAUD_RATE, CLKS_PER_BIT);

        apply_reset();

        // first pixel
        send_and_check(8'hAA, 8'hBB, 8'hCC);
        repeat (50) @(posedge clk);

        // second one just to make sure it works back to back
        send_and_check(8'hDD, 8'hEE, 8'hFF);
        repeat (50) @(posedge clk);

        if (error_count == 0)
            $display("=== tb_uart_tx: PASS ===");
        else
            $fatal(1, "=== tb_uart_tx: FAIL (%0d errors) ===", error_count);

        repeat (20) @(posedge clk);
        $finish;
    end

endmodule
