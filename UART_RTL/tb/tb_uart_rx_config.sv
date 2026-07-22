// tb_uart_rx_config.sv
// TB for uart_rx_config - mode/threshold UART line
// checks false start, framing, and a few normal bytes

`timescale 1ns / 1ps

module tb_uart_rx_config;

    localparam int SIM_CLOCK_FREQ = 1_000_000;
    localparam int BAUD_RATE = 115_200;
    localparam int CLKS_PER_BIT = SIM_CLOCK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS = CLKS_PER_BIT / 2;
    localparam real CLK_PERIOD_NS = 1_000_000_000.0 / SIM_CLOCK_FREQ;

    logic clk;
    logic n_rst;
    logic serial_rx_config;
    logic config_ack;
    logic [7:0] config_byte;
    logic config_ready;

    int error_count;

    uart_rx_config #(
        .CLOCK_FREQ(SIM_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .serial_rx_config(serial_rx_config),
        .config_ack(config_ack),
        .config_byte(config_byte),
        .config_ready(config_ready)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_uart_rx_config.vcd");
        $dumpvars(0, tb_uart_rx_config);
    end

    task automatic apply_reset();
        n_rst = 0;
        config_ack = 0;
        serial_rx_config = 1; // idle
        repeat (10) @(posedge clk);
        n_rst = 1;
        repeat (5) @(posedge clk);
    endtask

    // drive one UART byte onto the config line
    task automatic drive_uart_byte(
        input logic [7:0] data,
        input logic stop_bit
    );
        serial_rx_config = 0; // start
        repeat (CLKS_PER_BIT) @(posedge clk);

        for (int i = 0; i < 8; i++) begin
            serial_rx_config = data[i];
            repeat (CLKS_PER_BIT) @(posedge clk);
        end

        serial_rx_config = stop_bit;
        repeat (CLKS_PER_BIT) @(posedge clk);
        serial_rx_config = 1;
    endtask

    task automatic drive_false_start();
        serial_rx_config = 0;
        repeat (2) @(posedge clk);
        serial_rx_config = 1;
        repeat (CLKS_PER_BIT + HALF_CLKS) @(posedge clk);
    endtask

    task automatic wait_config_ready(input int timeout_clks);
        int t;
        t = 0;
        while (!config_ready && t < timeout_clks) begin
            @(posedge clk);
            t++;
        end
        if (!config_ready) begin
            $error("t=%0t timeout waiting for config_ready", $time);
            error_count++;
        end
    endtask

    task automatic check_byte(
        input logic [7:0] expected,
        input string tag
    );
        if (config_byte === expected)
            $display("PASS: %s got %02h", tag, config_byte);
        else begin
            $error("FAIL: %s expected %02h got %02h", tag, expected, config_byte);
            error_count++;
        end
    endtask

    task automatic ack_config();
        @(posedge clk);
        config_ack = 1;
        @(posedge clk);
        config_ack = 0;
        wait (!config_ready);
    endtask

    task automatic recv_and_check(
        input logic [7:0] expected,
        input string tag
    );
        drive_uart_byte(expected, 1'b1);
        wait_config_ready(5000);
        check_byte(expected, tag);
        ack_config();
    endtask

    initial begin
        error_count = 0;
        n_rst = 0;
        config_ack = 0;
        serial_rx_config = 1;

        $display("=== tb_uart_rx_config: start ===");
        $display("clk=%0d baud=%0d clks/bit=%0d", SIM_CLOCK_FREQ, BAUD_RATE, CLKS_PER_BIT);

        apply_reset();

        // glitch shouldn't count as a byte
        drive_false_start();
        repeat (CLKS_PER_BIT * 4) @(posedge clk);
        if (config_ready) begin
            $error("FAIL: false-start, config_ready went high");
            error_count++;
        end else
            $display("PASS: false-start ignored");
        repeat (20) @(posedge clk);

        // framing error - stop bit stuck low
        begin
            logic [7:0] bad_data;
            bad_data = 8'h77;
            serial_rx_config = 0;
            repeat (CLKS_PER_BIT) @(posedge clk);
            for (int i = 0; i < 8; i++) begin
                serial_rx_config = bad_data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end
            serial_rx_config = 0; // bad stop
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
        if (config_ready) begin
            $error("FAIL: framing, ready after bad STOP");
            error_count++;
        end else
            $display("PASS: framing error rejected");
        serial_rx_config = 1;
        repeat (CLKS_PER_BIT * 12) @(posedge clk);
        if (config_ready)
            ack_config();
        repeat (20) @(posedge clk);

        // mode byte (lower bits matter to pixel_controller)
        recv_and_check(8'h03, "mode");
        repeat (20) @(posedge clk);

        // threshold
        recv_and_check(8'h1F, "threshold");
        repeat (20) @(posedge clk);

        // one more just for back to back
        recv_and_check(8'hA5, "byte3");
        repeat (20) @(posedge clk);

        if (error_count == 0)
            $display("=== tb_uart_rx_config: PASS ===");
        else
            $fatal(1, "=== tb_uart_rx_config: FAIL (%0d errors) ===", error_count);

        repeat (50) @(posedge clk);
        $finish;
    end

endmodule
